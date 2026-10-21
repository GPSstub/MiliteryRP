# HK416 3D 모델 임포트 및 부드러운 반동

사용자가 제공한 **Meshy HK416 총몸 FBX**와 **탄창 FBX**는 서로 다른 독립 메시입니다. 별도 소총을 중복 제작하지 않고, 기존 훈련용 소총 Tool의 보이는 부분만 해당 모델로 교체합니다.

## 다운로드 및 준비

ChatGPT가 제공한 `HK416_Rojo_Assets.zip`을 다운로드해 압축을 해제하세요. GitHub에는 Luau 코드만 들어 있으며 **개인 업로드 모델 원본·메시를 GitHub에 공개 업로드하지 않았습니다.**

- `HK416_Body.obj`: 원본 총몸을 총구가 **로컬 -Z**를 바라보도록 회전, 총 길이 약 5.71 studs로 정렬, 약 19k 삼각형
- `HK416_Magazine.obj`: 탄창 FBX를 총몸 좌표계에 맞게 축·크기·장착 위치 정렬, 약 18k 삼각형
- `HK416_assembly_preview.glb`: 두 메시를 조립해 확인하기 위한 **미리보기**, Studio에서는 각각의 OBJ를 임포트하세요
- `HK416_*_normal_SOURCE.png`: 원본 FBX에 들어 있던 **노멀맵**. 일반 색상/알베도 텍스처가 아닙니다. 경량화 과정에서 UV를 근사 재투영했으므로 텍스처 이음새는 스튜디오에서 확인하세요
- `install_in_studio.luau`: 임포트한 메시를 게임의 `ServerStorage`로 정리하는 **Studio Command Bar용** 스크립트

## Roblox Studio에 설치 (최초 1회)

1. **Edit 모드**에서 기존 Rojo를 연결하고, 최신 코드가 있는지 확인합니다. `git switch main && git pull --ff-only origin main` 후 `rojo serve default.project.json`을 실행하세요(변경 사항이 main에 병합된 경우).
2. Roblox Studio 3D Importer에서 `HK416_Body.obj`와 `HK416_Magazine.obj`를 각각 임포트합니다. OBJ를 **한 번에 묶지 말고** 따로 임포트해야 탄창을 움직일 수 있습니다.
3. Explorer에서 각각 생성된 **MeshPart**(감싼 Model이 아니라 실제 MeshPart)를 `HK416_Body`, `HK416_Magazine`으로 이름을 바꿉니다. Workspace에 임시로 놓아도 됩니다.
4. Studio의 **View → Command Bar**를 열고 `install_in_studio.luau`의 코드를 붙여 실행합니다. 정상 설치되면 `ServerStorage/HK416Assets/Body`와 `ServerStorage/HK416Assets/Magazine`이 생깁니다.
5. **Play를 완전히 다시 시작**하세요. 서버가 새 캐릭터를 지급할 때 MeshPart가 있는지 확인하므로, 장착만 다시 해서는 기존 지급분이 바뀌지 않습니다.
6. Play의 `Backpack/훈련용 소총` Tool에서 `UsingHK416Mesh` Attribute가 `true`이면 HK416 3D 모델이 적용된 것입니다. `false`면 미등록 상태라 기존 Part 임시 모델이 보입니다.

`ServerStorage`는 현재 Rojo `default.project.json`의 관리 경로에 없습니다. 따라서 로컬 Studio 맵에 저장된 MeshPart와 GitHub Lua 코드는 별개입니다. **Rojo만 새로 받거나 새 컴퓨터에서 clone하면 3D 메시가 자동으로 생기지 않습니다.** 이 ZIP을 보관하고 Studio에서 한 번 임포트해야 합니다.

## 부품과 동작

- `Body` MeshPart: 서버가 Handle에 고정 Weld 연결
- `Magazine` MeshPart: 서버가 `MagazineJoint` Motor6D로 연결, 장전 시 분리/복귀
- `Bolt`: 원본 총몸 FBX가 **단일 메시**이므로 실제 노리쇠는 완전 분리할 수 없습니다. 별도의 작은 효과용 Part를 겹쳐 왕복시킵니다. 노리쇠까지 완전히 분리하려면 Bolt가 별도 메시인 원본 모델이 필요합니다.
- **발사 반동**: 카메라+총을 약간 위로 올린 뒤 프레임 독립적 임계감쇠 스프링으로 자연스럽게 제자리로 돌아옵니다. 연속 발사하면 속도가 누적되며, 갑자기 아래로 순간 이동하지 않습니다.
- **장전**: 총을 기울이고 탄창이 빠졌다 들어오며, 기존 재장전 시간/탄약 검증은 서버가 수행합니다.
- 총구는 변환된 모델 기준 약 `(0,0.32,-2.91)`에 있고, 모델 전방은 **로컬 -Z**입니다.

## 주의 사항

- 3D Importer와 R6/R15 애니메이션은 Roblox Studio 실제 플레이에서 아직 검증하지 않았습니다. 장착 회전이 어긋나면 `src/server/TrainingRifle.server.luau`의 `BASE_GRIP`을 조정할 수 있습니다.
- 원본 FBX에 별도 알베도 텍스처가 없어서 색상은 Roblox의 MeshPart Color/Material을 사용합니다. 포함된 노멀맵은 필요시 Roblox에 직접 업로드해 `SurfaceAppearance.NormalMap`에 적용하세요.
- 실제 Roblox 애니메이터 키프레임이 아닌 **스크립트 기반** 장착·발사·장전 연출입니다.
- 원본 `MilitaryRP.rbxlx`를 GitHub에 복원하지 않습니다. Studio에서 임포트한 모델은 Publish해야 실제 게시 게임에 유지됩니다.

테스트: `tests/rifle-recoil.spec.luau`의 스프링 상승·하강·복귀, 기존 `tests/training-rifle.spec.luau`의 탄약/발사율 보안 테스트, Studio에서 직접 모델 체결/사운드 확인.
