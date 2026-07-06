// UI 계층: 스토어만 바라본다 — api 직접 import 금지(eslint boundaries가 차단).
import { useEffect } from 'react';
import { useHealthStore } from '../../stores/healthStore';

interface HealthBadgeProps {
  // 콜백 prop은 on*, boolean은 is/has/can/should
  onRefresh?: () => void;
}

export function HealthBadge({ onRefresh }: HealthBadgeProps) {
  const { health, isLoading, errorMessage, loadHealth } = useHealthStore();

  useEffect(() => {
    void loadHealth();
  }, [loadHealth]);

  const handleRefreshClick = () => {
    void loadHealth();
    onRefresh?.();
  };

  if (isLoading) return <span role="status">확인 중…</span>;
  if (errorMessage) return <span role="alert">{errorMessage}</span>;
  if (!health) return null;

  return (
    <button type="button" onClick={handleRefreshClick}>
      서버 상태: {health.status}
    </button>
  );
}
