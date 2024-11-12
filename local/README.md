# MongoDB

### hostname 을 지정해야 하는 이유
replicaSet 이 hostname 기반으로 기본적으로 설정되는데 컨테이너의 hostname 를 지정하지 않으면 무작위로 생성된 containerId 를 hostname 으로 만들기 때문에 컨테이너를 재생성하면 datavolume 을 다시 물리더라도 replicaSet 구성에 실패함.

### eval 안에 들어가는 string parameter 는 escape 된 double quote 로 넣어야 함.
유저를 만들거나 sibling 을 추가할 때 eval 안에 들어가는 string parameter 는 escape 된 double quote 로 넣어야 함. 그렇지 않으면 eval 을 실행할 때 string 이 제대로 인식되지 않아 에러가 발생함.
