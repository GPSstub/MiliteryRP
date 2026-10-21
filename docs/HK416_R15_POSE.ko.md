# HK416 R15 양손 견착 (서버 IK)

R15 캐릭터는 기존의 왼쪽 어깨 C0만 꺾는 방법 대신 Roblox `IKControl`로 **왼팔 전체(LeftUpperArm → LeftHand)**를 움직입니다. 총을 장착하면 왼손이 총몸 앞쪽의 `Handle/SupportHandTarget`을 따라가고, 장전 중에는 `Magazine/MagazineHandTarget`으로 바뀌어 탄창 움직임을 따라갑니다. 장비를 벗으면 IK를 부드럽게 끕니다. IK 오브젝트는 서버에서 만들므로 다른 플레이어 클라이언트에도 전달됩니다.

## 테스트
1. Rojo로 변경 사항 동기화한 뒤 Play를 새로 시작하고 R15 캐릭터로 총을 장착합니다.
2. 플레이어 Tool의 `UsingR15SupportIK` 속성이 **true**인지 확인합니다. `Humanoid/TrainingRifleLeftHandIK`도 보여야 합니다.
3. 총을 들면 왼손이 핸드가드로, R 재장전 중에는 탄창으로 움직이는지 확인합니다. 장비를 해제하면 속성이 false가 되어야 합니다.
4. 다른 플레이어 클라이언트에서도 왼손이 비슷하게 보이는지 확인합니다.
5. 왼손이 어긋나면 `SupportHandTarget.Position`과 `MagazineHandTarget.Position`을 조절합니다. R15 체형/스케일에 따라 목표점 접근 범위가 달라집니다.
6. 총구가 실제로 뒤집혀 있다면 `R15_GRIP_YAW_DEGREES`를 180으로 수정한 뒤 Play로 테스트합니다. **기본값은 0**이며, 이전 스크린샷만으로 반대 방향을 단정하지 않습니다. 바뀐 방향이 올바른지 확인할 때마다 총을 새로 지급받아야 합니다.

## 제한
- 기존 R15 리그의 걷기/달리기 애니메이션은 그대로 쓰고, 왼손에 IK를 덧입힙니다. 자연스러운 2인칭 캐릭터 이동/무기 든 상태의 전용 상체 키프레임 애니메이션을 완전히 대체하지 않습니다.
- 원본 MeshPart 임포트와 `ServerStorage/HK416Assets`는 기존 방식 그대로입니다. 맵 파일은 GitHub에 다시 올리지 않습니다.
- Roblox Studio에서 다양한 R15 아바타 체형을 실제 검사해야 정밀한 손 위치를 확정할 수 있습니다.
