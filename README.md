# 모델1 방식의 회원제 게시판(JSP)
=============
### 1. 데이터베이스 연동
* 오라클 사용, JDBC API를 이용해서 JSP와 연동
sqlDeveloper 를 사용하여, 사용자 계정 생성 및 권한 설정 진행

<pre><code></code></pre>

- system 계정으로 접속하여 계정 생성, 접속 권한과 객체 생성 권한을 부여한다.
<pre><code>
create user musthave identified by 1234;
-- drop user musthave;
grant connect, resource to musthave;

conn musthave/1234;

--system계정에서 사용
</code></pre>

- 테이블 생성(member테이블과 board테이블) - 회원이 아닌 사람은 글을 게시할 수 없도록 외래키 지정
<pre><code>
create table member (
    id varchar2(10) primary key,
    pass varchar2(10) not null,
    name varchar2(30) not null,
    regidate date default sysdate not null  
);

create table board(
    num number primary key,
    title varchar2(200) not null,
    content varchar2(2000) not null,
    id varchar2(10) not null,
    postdate date default sysdate not null,
    visitcount number(6)
);

alter table board
    add constraint board_mem_fk foreign key(id)
    references member (id);
    
--일련번호용 시퀀스 생성
create sequence seq_board_num
    increment by 1
    start with 1
    minvalue 1
    nomaxvalue
    nocycle
    nocache;

insert into member(id, pass, name) values('musthave','1234','머스트해브');   
</code></pre>

- JDBC설정 및 데이터베이스 연결
![image](https://user-images.githubusercontent.com/86938974/165967936-f3894cc3-6051-4e98-b727-2a3262a34268.png)


 
  
