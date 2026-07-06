// Repository 계층: 도메인별 API 클라이언트 — 공용 래퍼(http.ts)만 사용한다.
import type { HealthStatus } from '../types/health';
import { httpGet } from './http';

export function fetchHealth(): Promise<HealthStatus> {
  return httpGet<HealthStatus>('/api/health');
}
