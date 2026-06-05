일단 S3 각자 가진 버킷으로 수정해서 사용하도록 하기 위해 ci/cd는 사용하지 않았고 lock 파일도 올리지 않았습니다.
수동으로 가져가셔서 init & apply 하시면 됩니다. <br><br>
[AWS]
-> 네트워크(vpc, subnet, igw, ngw) + EKS + Bastion Host가 생성됩니다.<br>
[Azure]
-> 네트워크(vpc, subnet, ngw) + AKS가 생성됩니다.<br><br>

-------------------------------<br>
[EKS]
namespace<br>
* default<br>
* argocd<br>
* petclinic

-------------------------------<br><br>

[필수 수정 사항]
* 버킷 수정
* 키 파일 생성 후 자신의 키로 접속 (추후 공용으로 사용하는 경우는 키 파일 공유 예정)

[선택 수정 사항]
* namespace
* 컨테이너 사양


* 이외의 수정 원하시면 말씀해주시면 제가 수정해서 다시 올리겠습니다
