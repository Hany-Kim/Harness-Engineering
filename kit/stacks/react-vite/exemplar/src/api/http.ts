// Repository 계층: HTTP 공용 래퍼 — 네트워크는 src/api/ 에서만 발생한다.
// WHY: 인증 헤더, 에러 변환, 재시도 정책을 한 곳에 모아야 컴포넌트가 네트워크
// 세부사항을 몰라도 된다. 컴포넌트의 fetch/axios 직접 import는 eslint가 차단한다.

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export async function httpGet<T>(path: string): Promise<T> {
  const response = await fetch(path, {
    headers: { Accept: 'application/json' },
  });
  if (!response.ok) {
    throw new HttpError(response.status, `GET ${path} failed`);
  }
  return (await response.json()) as T;
}
