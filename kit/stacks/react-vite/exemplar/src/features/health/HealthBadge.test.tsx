// 테스트 표본: given/when/then + happy path + 실패 경로 (testing-conventions 참조).
// WHY: 스토어는 실제로 쓰고, 네트워크(외부 시스템)만 목킹한다 — 목킹 경계 규칙.
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { HealthBadge } from './HealthBadge';
import * as healthApi from '../../api/health';
import { useHealthStore } from '../../stores/healthStore';

vi.mock('../../api/health');

describe('HealthBadge', () => {
  beforeEach(() => {
    useHealthStore.setState({ health: null, isLoading: false, errorMessage: null });
  });

  it('상태 조회에 성공하면 서버 상태를 보여준다', async () => {
    // given
    vi.mocked(healthApi.fetchHealth).mockResolvedValue({
      status: 'ok',
      checkedAt: '2026-07-06T00:00:00Z',
    });
    // when
    render(<HealthBadge />);
    // then
    expect(await screen.findByText(/서버 상태: ok/)).toBeInTheDocument();
  });

  it('상태 조회에 실패하면 사용자용 에러 메시지를 보여준다', async () => {
    // given
    vi.mocked(healthApi.fetchHealth).mockRejectedValue(new Error('boom'));
    // when
    render(<HealthBadge />);
    // then — 에러 원문(boom)이 아니라 변환된 메시지가 보여야 한다
    expect(await screen.findByRole('alert')).toHaveTextContent('상태 조회에 실패했습니다.');
  });
});
