import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../config/theme.dart';
import '../../models/hospital.dart';
import '../../models/triage_question.dart';
import '../../services/api_service.dart';
import 'ticket_screen.dart';
import '../../providers/auth_provider.dart';
import 'patient_drawer.dart';

class PreTriageScreen extends StatefulWidget {
  const PreTriageScreen({super.key});

  @override
  State<PreTriageScreen> createState() => _PreTriageScreenState();
}

class _PreTriageScreenState extends State<PreTriageScreen> with SingleTickerProviderStateMixin {
  int _step = 0;
  Hospital? _selectedHospital;
  TriageCategory? _selectedCategory;
  List<Hospital> _hospitals = [];
  double _painLevel = 0;
  bool _breathingDifficulty = false;
  String _symptomDuration = '1_24h';
  bool _loading = false;

  late AnimationController _animController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await apiService.get('/hospitals');
      if (!mounted) return;
      setState(() {
        _hospitals = (data['hospitals'] as List).map((h) => Hospital.fromJson(h)).toList();
      });
    } catch (e) {
      debugPrint('❌ Failed to load hospitals: $e');
    }
    if (!mounted) return;
    final ticket = context.read<TicketProvider>();
    await ticket.loadTriageCategories();
  }

  void _goToStep(int step) {
    _animController.reset();
    setState(() => _step = step);
    _animController.forward();
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
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: PatientDrawer(
        auth: auth,
        onTabSelected: (index) {
          Navigator.pop(context); // Close drawer
          Navigator.pop(context); // Close PreTriage
          // Note: Logic to switch tab in MainScreen isn't directly passed here unless we return result
          // But PreTriage is usually "new flow".
          // If user clicks a tab, we probably want to just go back.
        },
        selectedIndex: -1,
      ),
      // backgroundColor follows theme
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: _step > 0 ? () => _goToStep(_step - 1) : () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _stepTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.menu, color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? AlloUrgenceTheme.primaryLight : AlloUrgenceTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _animController,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildStep(ticket),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  // ── Step 0: Hospital Selection ────────────────────────────────
  Widget _buildHospitalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Où souhaitez-vous aller ?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('Sélectionnez un hôpital proche de vous',
          style: TextStyle(fontSize: 14, color: AlloUrgenceTheme.textSecondary)),
        const SizedBox(height: 20),
        ..._hospitals.asMap().entries.map((entry) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + entry.key * 100),
          builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HospitalCard(
              hospital: entry.value,
              selected: _selectedHospital?.id == entry.value.id,
              onTap: () { setState(() => _selectedHospital = entry.value); _goToStep(1); },
            ),
          ),
        )),
      ],
    );
  }

  // ── Step 1: Category Selection ────────────────────────────────
  Widget _buildCategoryStep(TicketProvider ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quel est votre problème ?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('Choisissez la catégorie la plus proche',
          style: TextStyle(fontSize: 14, color: AlloUrgenceTheme.textSecondary)),
        const SizedBox(height: 20),
        ...ticket.categories.asMap().entries.map((entry) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + entry.key * 80),
          builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child)),
          child: _CategoryCard(
            category: entry.value,
            selected: _selectedCategory?.id == entry.value.id,
            onTap: () { setState(() => _selectedCategory = entry.value); _goToStep(2); },
          ),
        )),
      ],
    );
  }

  // ── Step 2: Questions ─────────────────────────────────────────
  Widget _buildQuestionsStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final painColor = _painLevel >= 8 ? AlloUrgenceTheme.error
      : _painLevel >= 5 ? AlloUrgenceTheme.warning
      : AlloUrgenceTheme.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quelques questions rapides',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 24),

        // Pain level
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [AlloUrgenceTheme.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sentiment_dissatisfied_rounded, color: painColor, size: 22),
                  const SizedBox(width: 8),
                  Text('Niveau de douleur', style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${_painLevel.round()}',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: painColor),
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: painColor,
                  thumbColor: painColor,
                  inactiveTrackColor: painColor.withValues(alpha: 0.15),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _painLevel,
                  min: 0, max: 10,
                  divisions: 10,
                  onChanged: (v) => setState(() => _painLevel = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Aucune', style: TextStyle(fontSize: 12, color: AlloUrgenceTheme.textTertiary)),
                  Text('Extrême', style: TextStyle(fontSize: 12, color: AlloUrgenceTheme.textTertiary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Breathing
        _QuestionCard(
          icon: Icons.air_rounded,
          iconColor: _breathingDifficulty ? AlloUrgenceTheme.error : AlloUrgenceTheme.accent,
          question: 'Difficultés respiratoires ?',
          trailing: Switch.adaptive(
            value: _breathingDifficulty,
            activeColor: AlloUrgenceTheme.error,
            onChanged: (v) => setState(() => _breathingDifficulty = v),
          ),
        ),
        const SizedBox(height: 16),

        // Duration
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [AlloUrgenceTheme.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: AlloUrgenceTheme.primaryLight, size: 22),
                  const SizedBox(width: 8),
                  Text('Depuis combien de temps ?', style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary
                  )),
                ],
              ),
              const SizedBox(height: 12),
              ...['under_1h', '1_24h', 'over_24h'].map((v) {
                final labels = {'under_1h': 'Moins d\'une heure', '1_24h': '1 à 24 heures', 'over_24h': 'Plus de 24 heures'};
                final icons = {'under_1h': Icons.bolt_rounded, '1_24h': Icons.hourglass_bottom_rounded, 'over_24h': Icons.calendar_today_rounded};
                final selected = _symptomDuration == v;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _symptomDuration = v),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected 
                          ? AlloUrgenceTheme.primaryLight.withValues(alpha: 0.08) 
                          : (isDark ? AlloUrgenceTheme.darkSurfaceVariant : AlloUrgenceTheme.surfaceVariant),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AlloUrgenceTheme.primaryLight.withValues(alpha: 0.4) : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(icons[v]!, size: 18, color: selected ? AlloUrgenceTheme.primaryLight : (isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textTertiary)),
                          const SizedBox(width: 12),
                          Text(labels[v]!, style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary
                          )),
                          const Spacer(),
                          if (selected) const Icon(Icons.check_circle_rounded, color: AlloUrgenceTheme.primaryLight, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _goToStep(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlloUrgenceTheme.primaryLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Confirmation ──────────────────────────────────────
  Widget _buildConfirmStep() {
    final priority = _selectedCategory?.priority ?? 5;
    final color = AlloUrgenceTheme.getPriorityColor(priority);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Priority card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(AlloUrgenceTheme.getPriorityIcon(priority), size: 28, color: color),
              ),
              const SizedBox(height: 14),
              Text('Niveau estimé', style: TextStyle(fontSize: 14, color: AlloUrgenceTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                AlloUrgenceTheme.getPriorityLabel(priority),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
              ),
              Text('P$priority', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AlloUrgenceTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AlloUrgenceTheme.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Le niveau final sera confirmé par un professionnel de santé.',
                  style: TextStyle(fontSize: 13, color: AlloUrgenceTheme.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [AlloUrgenceTheme.cardShadow],
          ),
          child: Column(
            children: [
              _SummaryRow(icon: Icons.local_hospital_rounded, label: 'Hôpital', value: _selectedHospital?.name ?? '-'),
              const Divider(height: 20),
              _SummaryRow(icon: Icons.category_rounded, label: 'Motif', value: _selectedCategory?.label ?? '-'),
              const Divider(height: 20),
              _SummaryRow(icon: Icons.sentiment_dissatisfied_rounded, label: 'Douleur', value: '${_painLevel.round()}/10'),
              const Divider(height: 20),
              _SummaryRow(icon: Icons.air_rounded, label: 'Respiration', value: _breathingDifficulty ? 'Difficile' : 'Normale'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _loading ? null : _createTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: AlloUrgenceTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: _loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 22),
                    SizedBox(width: 10),
                    Text('Confirmer et obtenir mon ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
          ),
        ),
      ],
    );
  }
}

// ── Hospital Card ───────────────────────────────────────────────
class _HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final bool selected;
  final VoidCallback onTap;
  const _HospitalCard({required this.hospital, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AlloUrgenceTheme.primaryLight : Colors.transparent,
            width: selected ? 2 : 1,
          ),
          boxShadow: [AlloUrgenceTheme.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                image: hospital.imageUrl != null && hospital.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(hospital.imageUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: hospital.imageUrl == null || hospital.imageUrl!.isEmpty
                ? const Icon(Icons.local_hospital_rounded, color: AlloUrgenceTheme.primaryLight, size: 28)
                : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hospital.name, style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary
                  )),
                  const SizedBox(height: 4),
                  Text(hospital.address, style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Category Card ───────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final TriageCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AlloUrgenceTheme.getPriorityColor(category.priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : Colors.transparent, width: selected ? 2 : 1),
            boxShadow: [AlloUrgenceTheme.cardShadow],
          ),
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.label, style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary
                    )),
                    const SizedBox(height: 2),
                    Text(category.description, style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary
                    ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('P${category.priority}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Question Card ───────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String question;
  final Widget trailing;
  const _QuestionCard({required this.icon, required this.iconColor, required this.question, required this.trailing});

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AlloUrgenceTheme.cardShadow],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(question, style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary
          ))),
          trailing,
        ],
      ),
    );
  }
}

// ── Summary Row ─────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textTertiary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(
          fontSize: 14,
          color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary
        )),
        const Spacer(),
        Flexible(child: Text(value, style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary
        ), textAlign: TextAlign.right)),
      ],
    );
  }
}
