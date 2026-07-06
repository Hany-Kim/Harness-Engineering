<!-- 자동 생성: 원본 kit/skills/integrations/SKILL.md — scripts/render.sh가 갱신한다. Claude는 같은 내용을 Skill로 자동 로드하고, Codex는 이 문서를 읽는다. -->

# 외부 통합 (Jira / Slack)

참조값은 `harness/integrations.env`에 있다(비밀 아님). **실제 토큰은 저장소에
없다** — 접근은 MCP 서버(Atlassian/Slack) 경유가 기본이고 인증은 MCP가 처리한다.

## 값을 읽는 법

- `harness/integrations.env`의 변수를 참조한다. **빈 값이면 "미설정"** — 채널명이나
  프로젝트 키를 임의로 지어내지 말고 사람에게 확인한다.
- 이 값들은 참조용이다. 값이 자주 바뀌면 파일을 갱신하고 커밋한다(저장소가 진실).

## Jira (Atlassian MCP)

- 티켓 키는 `JIRA_PROJECT_KEY`로 시작한다(예: `PROJ-123`) — 브랜치명 규칙과
  연결된다(AGENTS.md Stage 0의 `<type>/<JIRA-KEY>-<slug>`).
- 티켓 조회/코멘트/상태 전이는 Atlassian MCP 도구로. URL은 `JIRA_TICKET_URL_PATTERN`
  의 `{KEY}`를 치환해 만든다.
- **상태 전이·코멘트·이슈 생성 등 티켓 변경은 외부 상태 변경이다 — 사람 승인 하에만.**

## Slack (Slack MCP)

- 대상 채널은 `SLACK_*_CHANNEL` 값을 쓴다 — 채널명을 지어내지 않는다.
- **메시지 발송은 외부 발행이다 — 사람 승인 하에, 시크릿/개인정보는 마스킹**(팀 전역
  §3). 한 번 보내면 회수되지 않는다.

## 시크릿 경계 (항상 보수적으로)

- 토큰·webhook secret을 `integrations.env`나 코드·로그·문서에 절대 쓰지 않는다.
- 직접 API가 불가피하면 토큰은 `.env`(gitignore)/시크릿 매니저에 두고, 참조 파일에는
  `*_TOKEN_ENV`로 **변수 이름만** 남긴다.
