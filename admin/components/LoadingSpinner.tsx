import { Loader2 } from 'lucide-react';

/**
 * Loading Spinner Component
 * Displays a centered loading spinner with optional text
 */
export default function LoadingSpinner({
    text = 'Chargement...',
    size = 'default'
}: {
    text?: string;
    size?: 'small' | 'default' | 'large';
}) {
    const sizeClasses = {
        small: 'w-4 h-4',
        default: 'w-8 h-8',
        large: 'w-12 h-12',
    };

    return (
        <div className="flex flex-col items-center justify-center gap-3 py-8">
            <Loader2 className={`${sizeClasses[size]} animate-spin text-primary-500`} />
            {text && (
                <p className="text-sm text-slate-400">{text}</p>
            )}
        </div>
    );
}
