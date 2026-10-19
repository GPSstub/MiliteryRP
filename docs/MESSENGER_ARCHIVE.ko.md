# 군대 RP 메신저 — 채널별 영구 보관 사용법

구현 브랜치: [main](https://github.com/GPSstub/MiliteryRP/tree/main)

## 채널을 만들 때 저장 방식 선택
메신저 → 설정 → **채널** → **+ 채널 만들기** → 채널 이름 입력.

저장 방식 버튼을 눌러 아래 둘 중 하나를 선택합니다.

- **일반 채널 · 기록 저장 안 함** (기본값): 기존 Roblox `TextChatService` 채팅입니다. 메시지는 접속 중 화면에만 표시되고 서버 종료/재접속 시 사라집니다.
- **영구 보관 · 기록 저장**: 공지·규칙 게시판입니다. Roblox `TextService`로 글을 제출할 때 **전체 공개 비채팅 텍스트 필터링**을 수행한 뒤 서버가 글을 저장하고, 권한이 있는 플레이어가 나중에 재접속해 다시 읽습니다.

기본 제공 **공지사항** 채널은 새 게임과 기존 설정 모두 영구 보관으로 취급합니다. **규칙** 채널은 새로 생성할 때 영구 보관을 선택하면 됩니다.

기존 채널도 메신저 설정 → 채널 선택 → **영구 저장 켜기/끄기**로 변경할 수 있습니다. 이 설정은 채널 설정을 관리할 권한이 있어야 수정할 수 있습니다.

## 게시판에서 지원하는 기능
- 글 작성, 작성자의 수정·삭제, 관리자의 삭제·고정·고정 해제
- 이모지 반응, 답장, 스레드, 작성자/날짜/본문 검색(불러온 기록 범위)
- 재접속 후 최신 40개부터 불러오기, 상단 **↑ 이전 영구 기록 불러오기**로 과거 글 더 보기
- `MessagingService` 변경 알림을 이용한 다른 Roblox 서버 화면 갱신(변경 신호가 누락되면 다시 채널 열기 또는 재접속으로 재조회)
- 모든 기록 읽기/쓰기/수정·삭제/반응/고정 작업은 서버에서 해당 채널 및 작성자/관리자 권한을 검증

## 저장 사양과 한계
- 저장소: Studio `MilitaryMessenger_Boards_Dev_v1`, 공개 게임 `MilitaryMessenger_Boards_v1` (서로 독립)
- 채널마다 **최대 300개** 게시글을 영구 저장합니다. 300개에 도달하면 과거 글을 자동으로 삭제하지 않고 **새 글 저장을 거부**합니다. 불필요한 글을 삭제하면 새 글을 작성할 수 있습니다.
- 저장은 `DataStore:UpdateAsync()`로 원자적으로 적용합니다. 필터링 실패나 DataStore 오류 시 저장 성공을 주장하지 않습니다.
- 보관 중지 옵션은 기존 저장 기록을 **삭제하지 않고 숨깁니다.** 다시 켜면 이전 게시글을 불러옵니다. 채널을 삭제해도 기존 기록은 자동으로 파기하지 않습니다.
- 게시판 글과 일반 채팅은 기술적으로 구분됩니다. 일반 채팅은 Roblox `TextChatService`를 사용하고, 영구 보관 채널은 서버가 필터링해 보관하는 **공지/규칙 게시판**으로 작동합니다.
- 모든 게시판 작성은 Roblox 채팅 가능 여부 및 역할 권한에 따라 차단될 수 있습니다.
- 게임 서버에 과도하게 높은 빈도로 공지를 작성하는 용도가 아닙니다. 실시간 대량 채팅 아카이브나 디스코드 전체 메시지 보관 대체재가 아닙니다.
- 일반 채팅의 기존 저장 정책, 계급 DataStore, 카테고리/역할 설정(현재 main 기준)은 수정하지 않습니다.

## 적용
로컬 작업 내용을 `git status`로 확인 후 현재 `main` 브랜치에서 동기화:

```bash
git switch main
git pull --ff-only origin main
rojo serve default.project.json
```

Roblox Studio에서 Rojo를 재연결하고, 반드시 게임을 게시한 상태로 **Game Settings → Security → Enable Studio Access to API Services**를 켜세요.

## 테스트 절차
1. 서버 실행 후 `ReplicatedStorage`에 `MessengerArchive` (RemoteFunction), `MessengerArchiveChanged` (RemoteEvent)가 보이는지 확인합니다.
2. **공지사항** 채널에서 글을 작성합니다. 스튜디오를 Stop → Play로 재시작한 뒤 공지사항에 동일한 기록이 표시되는지 확인합니다.
3. 채널 설정 → **+ 채널 만들기**에서 이름을 `규칙`으로 설정하고 **영구 보관**을 켜고 생성합니다. 작성 후 Stop → Play로 확인합니다.
4. `일반 채널`로 생성한 새 채널의 채팅은 재시작 시 사라지는지 확인합니다.
5. 영구 채널에서 답장/수정/삭제/핀/반응을 실행하고 재접속 시 결과가 유지되는지 확인합니다.
6. 40개가 넘는 글이 있을 때 **이전 영구 기록 불러오기** 버튼을 클릭하고 과거 글로 돌아가는지 확인합니다.
7. Studio **Start Server + 2 Players** 테스트로 일반 사용자에게 관리자 고정/삭제가 허용되지 않는지 검사합니다.
8. 다른 게임 서버를 띄워 영구 게시글이 전달되는지 확인합니다. MessagingService 전송 실패는 Output에서 확인합니다.
9. 실제 게임과 Studio의 데이터가 독립인 것은 의도된 동작입니다.

순수 Luau 테스트: `python3 tools/test.py` (`luau`, `luau-compile` 공식 CLI 필요). `tests/messenger-archive.spec.luau`에는 저장 정책·권한·페이지네이션·수정/삭제 테스트를 추가했습니다.

**검증 상태:** GitHub 소스 파일 정합성과 정적 구조 점검은 마쳤지만 Roblox Studio/공식 Luau CLI에서 실행한 통합 테스트는 아직 완료하지 못했습니다.

## 공식 개발 문서
- [Roblox: Text filtering](https://create.roblox.com/docs/ui/text-filtering)
- [Roblox: Data Stores](https://create.roblox.com/docs/cloud-services/data-stores)
- [Roblox: DataStore UpdateAsync](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore)
- [Roblox: TextChatService](https://create.roblox.com/docs/reference/engine/classes/TextChatService)
