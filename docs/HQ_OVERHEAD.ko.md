# HQ 팀 머리 위 로고 + HQ 표시

적용 브랜치: [main](https://github.com/GPSstub/MiliteryRP/tree/main)

## 동작

- `Teams.HQ` 소속이고 `Player.Neutral == false`인 플레이어만 머리 위에 **거북이·고양이 HQ 엠블럼과 'HQ' 텍스트**가 표시됩니다.
- HQ 소속 동안에는 **Roblox 플레이어 목록(leaderstats 계급)과 `Player.Rank` 속성에 `admin`**으로 표시됩니다. 일반 군 계급은 `RankId`, `RankCategory`, `RankOrder`에 남고 DataStore를 변경하지 않습니다. HQ에서 나가면 저장된 군 계급 표시가 돌아옵니다.
- HQ 멤버에게는 **기존 닉네임/일반 군 계급명/군 계급장**을 따로 표시하지 않습니다. 기존 기본 Roblox Humanoid 이름표도 숨깁니다.
- HQ에서 위관급·영관급·장관급 등 다른 팀으로 이동하면 **일반 닉네임+계급장+계급명** 표시로 되돌아갑니다.
- `/팀`으로 HQ에 임명하거나 HQ를 해제할 때, 플레이어가 리스폰하거나, 저장된 계급이 나중에 로드될 때도 자동으로 갱신됩니다. 렌더 순서를 검사해 이전 캐릭터의 머리 위 GUI가 다시 나타나는 현상을 줄였습니다.
- 이전 코드에서 `CharacterAppearanceLoaded`가 버전 번호를 전달하지 않아 머리 위 UI 재생성이 생략되던 문제를 수정했습니다. 서버 로그 저장 초기화가 실패하더라도 계급 표시 시스템이 시작되도록 초기화 순서를 조정했습니다.
- HQ 로고 렌더링이 실패하면 Output에 `[RankService] HQ badge render failed`가 표시되고, 최소한의 `HQ` 텍스트를 대신 표시합니다.
- **최신 UI 크기:** 로고 60px, 표시 최대 거리 25스터드, 머리 기준 오프셋 2.35스터드. 예전에 겹치던 금색 원형 장식은 제거했습니다.
- HQ 로고를 로드하지 못하면 작은 파란색 임시 표식이 보입니다. 실제 투명 PNG를 불러오면 임시 표식은 자동으로 숨깁니다.

## 흰색 사각형 배경 제거: 새 투명 PNG 등록 필요

스크린샷에서 흰 사각형이 보이던 원인은 **이전 이미지 에셋 `115201559367134` 자체가 배경이 불투명한 PNG**였기 때문입니다. Roblox `ImageLabel.BackgroundTransparency = 1`로는 텍스처 안의 흰색 픽셀을 지울 수 없습니다.

새로 준비한 **`HQLogo_Transparent.png`**는 기존 파란색 거북이·고양이 HQ 모양을 유지하면서 바깥의 흰색 배경을 알파 투명 처리했습니다. **기존 ID를 그대로 사용하면 여전히 흰색 사각형이 나옵니다. 반드시 새 투명 이미지를 Roblox 에셋으로 업로드해야 합니다.**

### 방법 A: Studio Asset Manager 이용 (코드 수정 없음)

1. ChatGPT 답변에 첨부된 `HQLogo_Transparent.png`를 저장합니다.
2. Roblox Studio에서 **Asset Manager → Images**를 열어 해당 PNG를 업로드합니다. 이미지의 이름을 **`HQLogo_Transparent`**로 유지하세요.
3. 업로드·검수가 완료된 후 게임을 실행합니다. `src/shared/HQLogoConfig.luau` 기본 설정 `LogoAssetId=0`, `LogoGameAssetName="HQLogo_Transparent"`이므로 `rbxgameasset://Images/HQLogo_Transparent`를 로드합니다.
4. 로고 아래에는 작은 `HQ` 텍스트가 나오며 기존 원형 장식과 흰 사각형은 나타나지 않습니다.

### 방법 B: 새 에셋 ID 입력

승인된 투명 PNG의 **새 Roblox 이미지 에셋 ID**를 발급받은 후 아래 설정만 교체해도 됩니다.

```lua
-- src/shared/HQLogoConfig.luau
LogoAssetId = 0, -- 이 0을 새 투명 PNG의 숫자 이미지 ID로 바꾸세요.
```

새 숫자 ID가 설정되면 게임 로컬 이미지 이름보다 우선 적용됩니다.

> 주의: 기존의 불투명 PNG ID `115201559367134`는 의도적으로 비활성화했습니다. 새 이미지를 아직 업로드하지 않았다면 머리 위에는 **작은 파란 임시 엠블럼**만 표시됩니다.

## 적용과 테스트

```bash
git status --short
git switch main
git pull --ff-only origin main
rojo serve default.project.json
```

Rojo로 Studio에 코드를 동기화한 다음, 다음 항목을 확인합니다.

1. HQ 팀으로 Play를 시작하면 머리 위 `RankTag`의 `DisplayMode`가 `HQ`, `HQLabel.Text`가 `HQ`인지 확인합니다. `HQEmblem` 내부에 이미지 또는 대체 로고가 보입니다. 플레이어 `Rank` 속성과 리더보드의 `계급` 값은 `admin`이어야 합니다.
2. HQ 관리 패널에서 다른 플레이어를 `HQ`로 이동시켜 같은 표시가 나타나는지 확인합니다.
3. 해당 플레이어를 `위관급` 등으로 이동하면 머리 위 HQ 표시가 사라지고 평소 계급장과 **원래 군 계급 값**이 돌아와야 합니다. `RankId`가 HQ 전후로 바뀌지 않는 것도 확인하세요.
4. HQ 멤버가 리스폰해도 로고와 HQ 표시가 유지되는지 확인합니다.
5. 새 투명 PNG `HQLogo_Transparent.png`를 업로드·승인받고 Studio에서 Play를 다시 시작해 **흰 사각형이 없는 HQ 로고**가 표시되는지 확인합니다. 크기가 60px인지도 확인하세요.
6. 서버 Command Bar에서 `tests/studio/hq-overhead-check.luau` 내용을 실행해 `[HQ OVERHEAD] Passed ... assertions`를 확인합니다.

대상 파일: `src/server/RankService.luau`, `src/server/HQOverheadBadge.luau`, `src/shared/HQLogoConfig.luau`, `src/client/HQLogoLoading.client.luau`

**여전히 머리 위가 비어 있다면:** Studio에서 **View → Output**을 열고 `[RankService]`, `[Main]` 오류를 확인하세요. Explorer의 `Players → 본인 → Team`이 실제 `HQ`이고 `Neutral=false`인지, Workspace 캐릭터 `Head → RankTag`에 `HQLabel`이 있는지도 확인해 주세요.

**검증 상태:** GitHub 소스 수정과 구조 검사는 완료했지만, 이 환경에서는 Roblox Studio 및 Luau CLI 실행 통합 테스트를 하지 못했습니다.

공식 문서: [Roblox ImageLabel](https://create.roblox.com/docs/reference/engine/classes/ImageLabel) / [Asset URI - rbxgameasset](https://create.roblox.com/docs/projects/assets)
