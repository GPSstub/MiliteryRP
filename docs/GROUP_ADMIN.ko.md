# Roblox 그룹 기반 관리자 권한 (그룹 1101574390)

적용 브랜치: [GitHub main](https://github.com/GPSstub/MiliteryRP/tree/main)

## 권한 규칙

**그룹 ID `1101574390`에서 그룹 랭크 200 이상**인 플레이어에게만 관리자 명령어 및 어드민 패널, 영구 서버 로그 조회 권한을 부여합니다.

| 그룹 랭크 | 관리자 권한 |
|---|---|
| 미가입 (0) | 없음 |
| 일반 구성원 (1–199) | 없음 |
| 운영진 (200–254) | 있음 |
| 그룹 소유자 (255) | 있음 |

이 기준은 **일단 보수적으로 선택한 기본값**입니다. 그룹에서 운영진 역할의 실제 랭크가 다르면 아래 설정을 변경하세요.

```luau
-- src/server/AdminGroupPolicy.luau
Policy.GROUP_ID=1101574390
Policy.MIN_ADMIN_RANK=200
```

그룹에 소속되었다는 이유만으로 모두에게 파괴·순간이동·계급 변경 명령을 허용하지 않습니다. Roblox 그룹 권한 자체는 그룹에 저장되므로 별도의 DataStore를 쓰지 않아도 재접속 시 새로 확인됩니다.

## HQ 팀과의 차이

- **Roblox 그룹**: 관리자 권한 기준입니다. 그룹 운영진이면 위관급·영관급·장관급 팀이거나 무소속이어도 관리자 명령어와 패널을 사용할 수 있습니다.
- **HQ 팀**: 머리 위 거북이·고양이 HQ 로고와 임시 `admin` 계급 표시를 포함한 **시각적 소속**입니다. HQ에 배정되었다고 관리자 권한을 얻지 않습니다.
- **`;팀 대상 HQ`**: 대상의 팀과 머리 위 표시만 변경합니다. 그룹 역할이나 운영진 등급은 변경하지 않습니다.
- 기존 제작자 계정은 게임 접속 시 HQ 팀으로 초기 배정되지만, **그룹 랭크 200 미만이면 명령어를 사용할 수 없습니다**. 운영진 권한을 받으려면 해당 Roblox 계정이 그룹의 운영진 역할을 가져야 합니다.
- HQ 팀 수동 배정은 기존대로 세션 전용입니다. 관리자 권한 유지와는 무관합니다.

## 대상 명령어

Roblox 기본 채팅창 또는 어드민 패널에서 `;`를 접두사로 입력합니다.

` ;계급 `, ` ;계급목록 `, ` ;팀 `, ` ;무적 `, ` ;비행 `, ` ;to `, ` ;here `, ` ;kill `, ` ;폭발 ` (공백 없이 사용).

명령어 처리 함수, 어드민 패널 명령 RemoteEvent, 채팅 명령, 팀 배정, 플레이어 제어 명령, 영구 관리 로그 조회에서 **서버의 동일한 그룹 권한 검사**를 사용합니다. 클라이언트가 로고/팀/권한 UI를 임의로 바꾸더라도 서버 권한이 생기지 않습니다.

## 그룹 확인 및 오류 처리

- `AdminGroupService`가 Roblox `GroupService:GetRolesInGroupAsync()`로 플레이어의 그룹 역할을 가져옵니다. 여러 역할을 보유한 경우 높은 랭크를 사용합니다.
- Roblox 역할 조회가 일시적으로 실패하면 `Player:GetRankInGroupAsync()`를 호환 경로로 시도합니다.
- 조회 실패 시 최대 3회 재시도하고 그동안 관리자 권한은 **거부**됩니다.
- `Players → 플레이어 → Attributes`에서 `AdminGroupStatus`(`Checking`, `Ready`, `Error`), `AdminGroupRank`, `CanUseAdminCommands`를 확인할 수 있습니다.
- 서버는 이 속성을 권한 근거로 믿지 않고 별도로 보관한 조회 결과만 검사합니다. 속성은 클라이언트 UI 표시용입니다.
- 접속 시 그룹 역할을 확인하고, 관리자 랭크로 확인된 접속자는 **180초 간격으로 재확인**합니다. 역할이 내려간 사실을 서버가 확인하면 무적·비행을 해제하고 관리자 기능을 차단합니다. 단, Roblox 그룹 API가 결과를 캐시하므로 즉시 반영을 보장하지 않습니다. 긴급 권한 회수에는 대상 서버에서 퇴장 처리하고 재접속으로 다시 확인하는 운영 절차가 필요합니다.
- 서버에서 그룹 서비스 응답이 계속 실패하면 Roblox Studio Output에 `[AdminGroupService]` 경고가 나고 권한이 차단됩니다. 이때 전체 HQ 팀을 관리자처럼 취급하는 우회는 하지 않습니다.

## 설치

Mac에서 기존 로컬 수정 파일을 확인한 다음:

```bash
git status --short
git switch main
git pull --ff-only origin main
rojo serve default.project.json
```

Studio Rojo 플러그인을 연결하고 Stop → Play로 재시작합니다. Studio의 로컬 테스트 클라이언트는 실제 그룹 가입 상태를 재현하지 못할 수 있으므로, 실제 그룹 운영진 계정으로 게시된 테스트 경험에 접속해 확인하는 것이 좋습니다.

## 테스트

1. 그룹 랭크가 200 이상인 계정으로 게임 접속 → 속성 `AdminGroupStatus=Ready`, `CanUseAdminCommands=true` 확인.
2. **HQ 팀이 아닌 상태**에서도 어드민 패널이 열리고 채팅창의 `;계급목록`이 성공하는지 확인.
3. 그룹 랭크가 200 미만인 계정을 HQ 팀으로 옮겨도 어드민 패널과 `;kill` 사용 권한이 생기지 않는지 확인.
4. 운영진의 그룹 랭크를 변경한 뒤 **재접속**하여 권한이 변경되는지 확인. 동시에 접속 중인 운영자는 그룹 API 캐시 만료 및 180초 재확인 이후 권한이 해제되는지 테스트.
5. 운영진으로 `;팀 대상 HQ`를 실행한 경우 대상의 그룹 권한은 그대로인지 확인.
6. 서버 로그 화면이 일반 그룹원에게 거절되는지 확인.
7. `tests/admin-group-policy.spec.luau`와 `tests/studio/hq-team-check.luau`로 정책 및 Studio 보안 검사를 수행합니다.

**검증 상태:** GitHub 코드와 테스트는 반영했으나 이 환경에서는 Roblox Studio 또는 실제 그룹 계정으로 게임 플레이 검증은 하지 못했습니다.

공식 참고: [Roblox GroupService](https://create.roblox.com/docs/reference/engine/classes/GroupService), [Player 그룹 관련 메서드](https://create.roblox.com/docs/reference/engine/classes/Player).
