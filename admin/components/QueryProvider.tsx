'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactNode, useState } from 'react';

/**
 * React Query Provider
 * Wraps the app with QueryClientProvider for data fetching/caching
 */
export default function QueryProvider({ children }: { children: ReactNode }) {
    const [queryClient] = useState(
        () =>
            new QueryClient({
                defaultOptions: {
                    queries: {
                        // Stale time: 5 minutes
                        staleTime: 5 * 60 * 1000,
                        // Cache time: 10 minutes
                        gcTime: 10 * 60 * 1000,
                        // Retry failed requests 2 times
                        retry: 2,
                        // Retry delay: exponential backoff
                        retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
                        // Refetch on window focus in production
                        refetchOnWindowFocus: process.env.NODE_ENV === 'production',
                        // Don't refetch on mount if data is fresh
                        refetchOnMount: false,
                    },
                    mutations: {
                        // Retry mutations once
                        retry: 1,
                    },
                },
            })
    );

    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
