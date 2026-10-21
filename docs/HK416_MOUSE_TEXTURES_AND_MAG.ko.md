# HK416: 기본 Grip 방향, 마우스 조준, 거꾸로 된 탄창, 텍스처

## 동작

- `BASE_GRIP` 기본 위치 `CFrame.new(0,-0.29,-0.42)` 복원. **Y축으로 180°만 회전**합니다. 이전 실험의 X축 -14° 경사는 제거했습니다.
- 분리된 HK416 탄창 OBJ가 거꾸로 끼워졌다는 피드백을 반영해 탄창 MeshPart의 **로컬 Z축으로 180°** 회전합니다. 삽입 높이 보정(+0.29 원본 OBJ 단위)은 유지합니다. Motor6D는 회전된 C0 위치로 복귀합니다.
- PC에서는 중앙 화면이 아닌 `Players.LocalPlayer:GetMouse().UnitRay`로 **실제 마우스 커서**의 조준 레이를 구하고, 캐릭터를 제외한 첫 Raycast 표적 지점을 서버로 보냅니다. 실제 탄환은 서버에서 무기 총구로부터 그 지점을 향해 Raycast합니다.
- 마우스가 없는 터치 기기에서는 이전과 같이 화면 중앙을 기준으로 발사합니다. PC의 기존 화면 중앙 '+' 표시는 마우스 조준과 불일치해 숨겼습니다.
- 기존 서버 탄약/쿨다운/사거리/팀 보호 규칙과 R15 왼손 IK, 스프링 반동은 유지합니다.

## 사용자 업로드한 텍스처 4장을 적용하려면

**텍스처 이미지 파일과 Roblox Asset ID는 서로 다릅니다.** 메시에 넣은 이미지가 Roblox 게임에서 표시되려면, Roblox Studio **Asset Manager**에 각 이미지가 업로드되고 그 이미지의 사용 권한이 있어야 합니다. 채팅에 보낸 그림 4장은 업로드만으로는 Roblox 경험의 Asset ID가 생성되지 않습니다.

1. 네 장의 이미지에서 어떤 것이 `ColorMap`(일반 색상), `NormalMap`(대체로 파랑/보라), `RoughnessMap`(거칠기, 회색조), `MetalnessMap`(금속성, 회색조)인지 확인합니다. **보내준 네 장이 반드시 이 네 종류라고 가정하지 마세요.**
2. Studio Asset Manager에 필요한 텍스처 파일을 업로드하고 각 **이미지 Asset ID**를 기록합니다.
3. `tools/hk416_apply_textures.studio.luau`를 열어 `Body` / `Magazine`별 슬롯에 `rbxassetid://12345` 형식으로 올바른 ID를 입력합니다. 텍스처가 특정 파트에 해당하지 않으면 그 파트의 ID를 비워 두세요.
4. **Play 중지가 된 Edit 모드**에서 Roblox Studio **View → Command Bar**에 코드를 붙여 실행합니다.
5. Explorer → ServerStorage → HK416Assets → Body/Magazine 아래에 `SurfaceAppearance`가 달렸는지 확인하고 맵을 저장합니다. Play를 다시 시작하면, 서버가 MeshPart를 복제할 때 `SurfaceAppearance`도 함께 복제합니다. 별도로 GitHub나 Rojo에 텍스처를 올릴 필요는 없습니다.

**중요: 현재 Body/Magazine OBJ는 FBX를 경량화하는 과정에서 UV를 근사 매핑했습니다.** 텍스처가 뒤틀리거나 이음새가 있으면 단순 Material 설정 문제가 아니라 메시 UV 문제일 수 있습니다. 이 경우 원본 FBX UV를 유지하는 방식으로 다시 경량화·임포트해야 합니다.

## 스튜디오 확인

1. `git pull --ff-only origin main` 후 Rojo 재연결 및 Play **완전 재시작**.
2. `Tool` 속성에서 `GripYawDegrees=180`, `GripPitchDegrees=0`, `MagazineFlipDegrees=180` 확인.
3. R15 3인칭에서 총구 방향, 총과 왼손 그립 및 탄창 상단 결합부를 확인합니다.
4. 커서를 화면 중앙에서 옆으로 옮겨 쏴 보고 트레이서와 피격점이 **마우스 커서 위치**를 향하는지 확인합니다. 좌우 각도가 너무 크거나 캐릭터 뒤의 목표를 겨누면 서버의 뒤쪽 발사 제한으로 요청이 차단될 수 있습니다.
5. 전용 어깨/장전 애니메이션은 추가 보정이 가능하며, 원본 MeshPart/맵은 그대로 유지됩니다.
