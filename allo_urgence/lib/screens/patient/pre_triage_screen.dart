import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../config/theme.dart';
import '../../models/hospital.dart';
import '../../models/triage_question.dart';
import '../../services/api_service.dart';
import 'ticket_screen.dart';

class PreTriageScreen extends StatefulWidget {
  const PreTriageScreen({super.key});

  @override
  State<PreTriageScreen> createState() => _PreTriageScreenState();
}

class _PreTriageScreenState extends State<PreTriageScreen> {
  int _step = 0; // 0=hospital, 1=category, 2=questions, 3=confirm
  Hospital? _selectedHospital;
  TriageCategory? _selectedCategory;
  List<Hospital> _hospitals = [];
  Map<String, dynamic> _answers = {};
  double _painLevel = 0;
  bool _breathingDifficulty = false;
  String _symptomDuration = '1_24h';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load hospitals
    try {
      final data = await apiService.get('/hospitals');
      setState(() {
        _hospitals = (data['hospitals'] as List).map((h) => Hospital.fromJson(h)).toList();
      });
    } catch (e) {
      // fallback
    }
    // Load triage categories
    final ticket = context.read<TicketProvider>();
    await ticket.loadTriageCategories();
  }

  Future<void> _createTicket() async {
    if (_selectedHospital == null || _selectedCategory == null) return;

    setState(() => _loading = true);

    final ticket = context.read<TicketProvider>();
    final success = await ticket.createTicket(
      hospitalId: _selectedHospital!.id,
      categoryId: _selectedCategory!.id,
      triageAnswers: {
        'pain_level': _painLevel.round(),
        'breathing': _breathingDifficulty,
        'symptom_duration': _symptomDuration,
      },
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success && ticket.activeTicket != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TicketScreen(ticketId: ticket.activeTicket!.id)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ticket.error ?? 'Erreur'), backgroundColor: AlloUrgenceTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _step > 0 ? () => setState(() => _step--) : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: Colors.grey[200],
            color: AlloUrgenceTheme.primaryBlue,
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(ticket),
            ),
          ),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0: return 'Choisir l\'hôpital';
      case 1: return 'Motif de visite';
      case 2: return 'Questions rapides';
      case 3: return 'Confirmation';
      default: return '';
    }
  }

  Widget _buildStep(TicketProvider ticket) {
    switch (_step) {
      case 0: return _buildHospitalStep();
      case 1: return _buildCategoryStep(ticket);
      case 2: return _buildQuestionsStep();
      case 3: return _buildConfirmStep();
      default: return const SizedBox();
    }
  }

  // Step 0: Hospital selection
  Widget _buildHospitalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Où souhaitez-vous aller ?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ..._hospitals.map((h) => _SelectionCard(
          title: h.name,
          subtitle: h.address,
          icon: Icons.local_hospital,
          selected: _selectedHospital?.id == h.id,
          onTap: () => setState(() { _selectedHospital = h; _step = 1; }),
        )),
      ],
    );
  }

  // Step 1: Category selection
  Widget _buildCategoryStep(TicketProvider ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quel est votre problème principal ?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Choisissez la catégorie la plus proche de votre situation.', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 20),
        ...ticket.categories.map((cat) => _CategoryCard(
          category: cat,
          selected: _selectedCategory?.id == cat.id,
          onTap: () => setState(() { _selectedCategory = cat; _step = 2; }),
        )),
      ],
    );
  }

  // Step 2: Follow-up questions
  Widget _buildQuestionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quelques questions rapides', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),

        // Pain level
        const Text('Niveau de douleur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('0', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Slider(
                value: _painLevel,
                min: 0, max: 10,
                divisions: 10,
                label: _painLevel.round().toString(),
                activeColor: _painLevel >= 8 ? AlloUrgenceTheme.error : _painLevel >= 5 ? AlloUrgenceTheme.warning : AlloUrgenceTheme.success,
                onChanged: (v) => setState(() => _painLevel = v),
              ),
            ),
            Text('10', style: const TextStyle(fontSize: 16)),
          ],
        ),
        Center(child: Text('${_painLevel.round()}/10', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _painLevel >= 8 ? AlloUrgenceTheme.error : Colors.black))),
        const SizedBox(height: 24),

        // Breathing
        _QuestionSwitch(
          question: 'Avez-vous des difficultés à respirer ?',
          value: _breathingDifficulty,
          onChanged: (v) => setState(() => _breathingDifficulty = v),
        ),
        const SizedBox(height: 20),

        // Duration
        const Text('Depuis combien de temps ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        ...['under_1h', '1_24h', 'over_24h'].map((v) {
          final labels = {'under_1h': 'Moins d\'une heure', '1_24h': '1 à 24 heures', 'over_24h': 'Plus de 24 heures'};
          return RadioListTile<String>(
            title: Text(labels[v]!, style: const TextStyle(fontSize: 16)),
            value: v,
            groupValue: _symptomDuration,
            onChanged: (val) => setState(() => _symptomDuration = val!),
          );
        }),
        const SizedBox(height: 24),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 3),
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }

  // Step 3: Confirmation
  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AlloUrgenceTheme.getPriorityColor(_selectedCategory?.priority ?? 5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AlloUrgenceTheme.getPriorityColor(_selectedCategory?.priority ?? 5).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(AlloUrgenceTheme.getPriorityIcon(_selectedCategory?.priority ?? 5), size: 48,
                color: AlloUrgenceTheme.getPriorityColor(_selectedCategory?.priority ?? 5)),
              const SizedBox(height: 12),
              Text('Niveau estimé', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(AlloUrgenceTheme.getPriorityLabel(_selectedCategory?.priority ?? 5),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AlloUrgenceTheme.getPriorityColor(_selectedCategory?.priority ?? 5))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Le niveau final sera confirmé par un professionnel de santé.',
                  style: TextStyle(fontSize: 14, color: Colors.amber.shade900)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary
        _summaryRow('Hôpital', _selectedHospital?.name ?? '-'),
        _summaryRow('Motif', _selectedCategory?.label ?? '-'),
        _summaryRow('Douleur', '${_painLevel.round()}/10'),
        _summaryRow('Difficulté respiratoire', _breathingDifficulty ? 'Oui' : 'Non'),

        const SizedBox(height: 32),
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _loading ? null : _createTicket,
            style: ElevatedButton.styleFrom(backgroundColor: AlloUrgenceTheme.success),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('✅ Confirmer et obtenir mon ticket', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionCard({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected ? const BorderSide(color: AlloUrgenceTheme.primaryBlue, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AlloUrgenceTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AlloUrgenceTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              )),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final TriageCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AlloUrgenceTheme.getPriorityColor(category.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(category.description, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('P${category.priority}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionSwitch extends StatelessWidget {
  final String question;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _QuestionSwitch({required this.question, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: Text(question, style: const TextStyle(fontSize: 16))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AlloUrgenceTheme.error,
          ),
        ],
      ),
    );
  }
}
