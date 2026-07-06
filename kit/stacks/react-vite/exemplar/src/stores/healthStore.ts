// Service 계층: zustand 스토어 — 상태 + "액션"을 노출한다.
// WHY: 컴포넌트에 raw setter를 주면 비즈니스 규칙(로딩/에러 전이)이 UI에 흩어진다.
// 액션만 노출하면 상태 전이가 이 파일 하나에서 검증 가능하다.
import { create } from 'zustand';
import type { HealthStatus } from '../types/health';
import { fetchHealth } from '../api/health';

interface HealthState {
  health: HealthStatus | null;
  isLoading: boolean;
  errorMessage: string | null;
  loadHealth: () => Promise<void>;
}

export const useHealthStore = create<HealthState>((set) => ({
  health: null,
  isLoading: false,
  errorMessage: null,

  loadHealth: async () => {
    set({ isLoading: true, errorMessage: null });
    try {
      const health = await fetchHealth();
      set({ health, isLoading: false });
    } catch (error) {
      // WHY: 에러 원문을 UI에 그대로 노출하지 않는다 — 사용자 메시지로 변환.
      set({ errorMessage: '상태 조회에 실패했습니다.', isLoading: false });
      void error;
    }
  },
}));
