# 군용 메신저 · 디스코드형 부가 기능 (main)

이 문서는 **2026-10-20**부터 `main` 브랜치에 추가한 디스코드형 텍스트 메신저 기능을 설명합니다. Discord의 제품 전체를 복제했다는 뜻이 아니라, Roblox 내 게임 채팅에서 지원되는 기능만 구현했습니다.

## 기능
| 기능 | 조작 | 범위 |
|---|---|---|
| 메시지 답장 | 메시지 아래 `↩ 답장` | 같은 채널, Roblox TextChatService 필터 적용 |
| 스레드 | `⌗ 스레드`, 상단 `← 스레드 나가기` | 같은 채널의 스레드 대화 표시 |
| 메시지 수정 | 자신이 보낸 메시지 `··· → ✎ 수정` | 원본 수정은 필터를 거친 **새 채팅 이벤트**로 전달해 메신저 UI의 텍스트를 교체 |
| 삭제 | 자신 또는 채널 관리자 `··· → 🗑 삭제` | 현재 접속 중인 클라이언트의 해당 메시지 표시 제거 |
| 고정/해제 | 통신망 관리자 `··· → 📌 고정` | 서버 세션 메타데이터, 헤더 `📌` 목록 |
| 반응 | `☺ 반응` 또는 기존 반응 버튼 | 👍 ❤️ 😂 🔥 ✅ 🎉, 서버가 사용자별 토글 및 인원수 검증 |
| 마크다운 | **굵게**, *기울임*, `__밑줄__`, `~~취소선~~`, 인라인 코드 | 메시지는 먼저 Roblox 필터를 거치며 RichText 문자 이스케이프 후 표시 |
| 채널 음소거 | 채널 헤더 `🔔 / 🔕` | 현재 접속 중 개인 설정; 일반 미확인 알림 숨김, @이름 멘션 알림 예외 |
| 모두 읽음 | 헤더 `✓` 또는 새 메시지 알림 확인 | 현재 채널 미확인 수 리셋 |
| 대화 검색 | 검색창 | 현재 클라이언트가 받은 메시지 대상; `from:`, `in:`, `before:`, `after:`, `has:pin`, `is:thread` |
| 단축키 | M: 열기/닫기, Cmd/Ctrl+F: 검색, Cmd/Ctrl+P: 고정 목록, ↑: 최근 본인 글 수정 | 대화창 내 |

## 보안/기술적 범위
- **일반 채팅은 영구 저장하지 않습니다.** 단, 공지사항과 영구 보관을 선택한 채널은 별도의 필터링된 게시판 기록을 DataStore에 저장합니다. 자세한 사용법은 [채널별 영구 보관 안내](MESSENGER_ARCHIVE.ko.md)를 확인하세요. 기존 설정/계급 DataStore는 그대로 유지됩니다.
- 일반 채팅은 기존 `TextChannel:SendAsync`를 통해 Roblox가 수신자별로 필터링합니다. 영구 채널은 일반 채팅과 별도로 서버가 `TextService` 전체 공개용 필터링을 적용하고 보관합니다.
- `MessengerActions.luau`는 **게임 서버의 RAM에서만** 최근 2,000개 메시지의 ID/작성자/채널/반응/고정/삭제 상태를 관리합니다. 서버를 나가면 사라집니다.
- 일반 채팅은 클라이언트가 접속 중 최근 300개까지만 보관합니다. 영구 보관 채널은 서버에서 필터링·저장한 게시글 300개를 재접속 시 최대 40개씩 불러옵니다.
- 관리자 변경은 `MANAGE_SETTINGS` 및 채널 관리 권한이 모두 필요합니다. 사용자는 자기 메시지만 삭제·수정할 수 있습니다. 다른 부대의 `unit` 채널 내용은 표시하거나 조작할 수 없습니다.
- Discord의 파일 업로드/파일 보관, 음성/영상 통화, 화면 공유, 서버 초대, 개인 DM, 봇, 이모지 업로드, 영구 스레드/검색 인덱스, 서버 간 실시간 메시지 동기화는 **이번 구현에 포함하지 않습니다.** Roblox API·미디어 정책·계정 간 메시징 규정을 고려한 별도의 구현이 필요합니다.
- 메신저 설정/권한은 이전과 같이 DataStore에 저장됩니다. 일반 채팅 본문과 반응은 저장되지 않지만, 영구 채널 게시판의 글·반응·고정·수정·삭제 상태는 별도 DataStore에 반영됩니다.
- TextChatService 로컬 메시지 필터링을 우회하지 마십시오. 멋대로 RemoteEvent로 원본 메시지 본문을 주고받지 마십시오.

## 참고한 공식 문서
- Discord: [Pin Messages FAQ](https://support.discord.com/hc/en-us/articles/221421867-Pin-Messages-FAQ)
- Discord: [Search](https://support.discord.com/hc/en-us/articles/115000468588-How-to-Use-Search-on-Discord)
- Discord: [Threads](https://support.discord.com/hc/en-us/articles/4403205878423-Threads-FAQ)
- Discord: [Reactions](https://support.discord.com/hc/ko/articles/12102061808663)
- Discord: [Channel notification mute](https://support.discord.com/hc/en-us/articles/209791877-How-do-I-mute-and-disable-notifications-for-specific-channels)
- Discord: [Inbox / Mark Read](https://support.discord.com/hc/en-us/articles/360045027712-Inbox-FAQ)
- Roblox: [TextChannel](https://create.roblox.com/docs/reference/engine/classes/TextChannel), [TextChatService](https://create.roblox.com/docs/reference/engine/classes/TextChatService)
- Roblox: [Text filtering](https://create.roblox.com/docs/ui/text-filtering)

## 동기화 및 수동 QA
```sh
git switch main
git pull origin main
rojo serve default.project.json
```

Studio의 Rojo 플러그인에서 서버에 연결 후 다음을 확인하세요.
1. `ServerScriptService`에 `MessengerActions`와 변경된 `MessengerRuntime`, `ReplicatedStorage/Shared`에 `MessengerActionProtocol`이 보여야 합니다.
2. Studio의 `Test → Start`로 2인 이상 테스트하고, 서로 채팅을 주고받아 답장·스레드·반응·수정·삭제·핀을 확인합니다.
3. 일반 사용자의 다른 사람 메시지 삭제/핀은 거부되어야 하며, 관리자 권한을 가진 계정은 고정 및 관리 삭제가 가능해야 합니다.
4. 채널 전환, 채널 권한 변경 및 소속 부대 변경 시 접근 권한이 다시 적용되는지 확인합니다.
5. Search `from:이름`, `has:pin`, `is:thread`; 음소거 후 멘션 알림; 편집 중 Esc; 버튼의 모바일 배치를 확인합니다.
6. Stop → Play 후 **일반 채팅**은 초기화되지만, **공지사항 및 영구 보관 채널**의 게시글과 반응·고정 상태는 복원되어야 합니다.

기존 테스트:
```sh
python3 tools/test.py
```
위 테스트 실행에는 공식 Luau CLI의 `luau`와 `luau-compile`이 필요합니다. Discord 기능을 추가하면서 `tests/messenger-actions.spec.luau` 및 `tests/studio/messenger-ui-check.luau`도 갱신했습니다.

**테스트 상태:** 이 변경을 작성한 환경에서는 Roblox Studio/공식 Luau CLI를 실행하지 못했으므로 컴파일 또는 실게임 동작 성공을 보증하지 않습니다. Studio Output 오류가 있다면 파일과 줄 번호를 확인해 수정하세요.
