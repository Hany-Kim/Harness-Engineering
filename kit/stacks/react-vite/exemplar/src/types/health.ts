// Types 계층: 도메인 타입만. 어떤 계층도 import하지 않는다.
export interface HealthStatus {
  status: 'ok' | 'degraded' | 'down';
  checkedAt: string; // ISO-8601
}
