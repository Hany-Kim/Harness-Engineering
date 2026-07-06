<!-- 자동 생성: 원본 kit/skills/db-migration/SKILL.md — scripts/render.sh가 갱신한다. Claude는 같은 내용을 Skill로 자동 로드하고, Codex는 이 문서를 읽는다. -->

# DB 마이그레이션 컨벤션

## 원칙

- **forward-only**: 적용된 마이그레이션은 절대 수정하지 않는다 — 되돌릴 일이 있으면
  보상 마이그레이션을 새로 추가한다(체크섬/이력 불일치 방지).
- 마이그레이션은 사람 리뷰 후에만 운영에 반영된다. 에이전트가 직접 운영 DB에
  적용하지 않는다.
- 파괴적 변경(DROP, TRUNCATE, WHERE 없는 UPDATE/DELETE)은 실행 전 반드시 사람 승인.

## 네이밍

- Flyway: `V{yyyyMMddHHmmss}__{why_snake_case}.sql` — 버전과 설명 사이는
  **더블 언더스코어**. 타임스탬프 버전이라 브랜치 간 충돌이 없다.
  예: `V20260706143000__add_user_email_index.sql`
- Alembic: revision message에 WHY를 snake_case로. autogenerate 결과는 반드시
  손으로 검토한다(의도치 않은 drop 포함 여부).

## 체크리스트 (완료 기준)

- [ ] 스키마 변경과 코드 변경이 같은 계획(docs/plans/)에 묶여 있다.
- [ ] 롤백 전략이 계획 §6에 있다(보상 마이그레이션 초안 포함).
- [ ] 대량 데이터 변경이면 배치/락 영향과 실행 시간 추정을 계획에 명시했다.
- [ ] 로컬/테스트 DB에서 적용·재적용을 확인했다.
