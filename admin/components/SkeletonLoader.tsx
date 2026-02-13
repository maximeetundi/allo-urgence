/**
 * Skeleton Loader Component
 * Displays animated placeholder while content is loading
 */
export default function SkeletonLoader({
    className = '',
    variant = 'default'
}: {
    className?: string;
    variant?: 'default' | 'card' | 'table' | 'text';
}) {
    const baseClass = 'animate-pulse bg-slate-700/50 rounded';

    if (variant === 'card') {
        return (
            <div className={`glass-card p-6 ${className}`}>
                <div className="space-y-4">
                    <div className={`${baseClass} h-6 w-1/3`}></div>
                    <div className={`${baseClass} h-4 w-full`}></div>
                    <div className={`${baseClass} h-4 w-5/6`}></div>
                    <div className={`${baseClass} h-4 w-4/6`}></div>
                </div>
            </div>
        );
    }

    if (variant === 'table') {
        return (
            <div className={`space-y-3 ${className}`}>
                {[...Array(5)].map((_, i) => (
                    <div key={i} className="flex gap-4">
                        <div className={`${baseClass} h-12 flex-1`}></div>
                        <div className={`${baseClass} h-12 flex-1`}></div>
                        <div className={`${baseClass} h-12 flex-1`}></div>
                    </div>
                ))}
            </div>
        );
    }

    if (variant === 'text') {
        return (
            <div className={`space-y-2 ${className}`}>
                <div className={`${baseClass} h-4 w-full`}></div>
                <div className={`${baseClass} h-4 w-5/6`}></div>
                <div className={`${baseClass} h-4 w-4/6`}></div>
            </div>
        );
    }

    // Default variant
    return <div className={`${baseClass} ${className}`}></div>;
}
