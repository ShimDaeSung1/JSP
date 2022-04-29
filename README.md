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
JDBC로 오라클을 이용하려면 오라클이 제공하는 JDBC드라이버가 필요하다. 오라클을 이미 설치하였으므로 드라이버 파일은 별도로 다운로드 받지 않는다. 다음 경로를 확인하여 jar파일을 찾는다. 그 중 ojdbc6.jar가 오라클 JDBC드라이버이다. 개별 프로젝트의 WEB-INF 하위의 lib 폴더에 추가하면 작업 공간을 변경하거나 배포 시에도 드라이버가 함께 따라간다는 편리함이 있다.
![image](https://user-images.githubusercontent.com/86938974/165967936-f3894cc3-6051-4e98-b727-2a3262a34268.png)
다음과 같이 추가해준다.
![image](https://user-images.githubusercontent.com/86938974/165968554-828df43f-7e64-4c7c-aa6d-7c8405eeae96.png)

- 연결 관리 클래스 작성
JDBC드라이버를 이용하여 DB와의 연결을 관리하는 클래스 작성

 
 Java Resources -> common -> JDBConnect.java 생성
  ![image](https://user-images.githubusercontent.com/86938974/165968945-9a6c6b3b-7387-4297-809a-9c47c49164cc.png)
  
<pre><code>
  package common;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

import javax.servlet.ServletContext;

public class JDBConnect {
    public Connection con;
    public Statement stmt;  
    public PreparedStatement psmt;  
    public ResultSet rs;
</code></pre>
*Connection : 데이터베이스와 연결 담당
*Statement : 인파라미터가 없는 정적 쿼리문 실행
*PreparedStatement : 인파라미터가 있는 동적 쿼리문 실행
*ResultSet : SELECT 쿼리문의 결과 저장시 사용

- JDBC 드라이버를 메모리에 로드한다. Class의 forName()은 new키워드 대신 클래스명을 통해 직접 객체를 생성한 후 메모리에 로드한다. 인수로는 오라클 드라이버를 넣는다.
- 그 후 DB에 연결하기 위해 URL, ID, 패스워드를 넣는다. 커넥션 객체를 통해 오라클 연결. close()메서드를 통해 DB관련 작업을 마치고 자원 절약을 위해 연결 해제해준다.
<pre><code>
public JDBConnect() {
        try {
            // JDBC 드라이버 로드
            Class.forName("oracle.jdbc.OracleDriver");

            // DB에 연결
            String url = "jdbc:oracle:thin:@localhost:1521:xe";  
            String id = "musthave";
            String pwd = "1234"; 
            con = DriverManager.getConnection(url, id, pwd); 

            System.out.println("DB 연결 성공(기본 생성자)");
        }
        catch (Exception e) {            
            e.printStackTrace();
        }
    }
</code></pre>

- 연결 설정 개선
- 서버 환경과 관련된 정보들은 한 곳에서 관리하는 것이 좋다. 주로 web.xml에 입력해놓고 필요시 application 내장 객체를 통해 얻어온다.
- ![image](https://user-images.githubusercontent.com/86938974/165970228-da604235-b5de-4aff-8284-a2d7cbd8ea9a.png)

<pre><code>
<context-param>
    <param-name>OracleDriver</param-name>
    <param-value>oracle.jdbc.OracleDriver</param-value>
  </context-param>
  <context-param>
    <param-name>OracleURL</param-name>
    <param-value>jdbc:oracle:thin:@localhost:1521:xe</param-value>
  </context-param>
  <context-param>
    <param-name>OracleId</param-name>
    <param-value>musthave</param-value>
  </context-param>
  <context-param>
    <param-name>OraclePwd</param-name>
    <param-value>1234</param-value>
  </context-param>
</code></pre>

-JDBConnect.java에 두 번째 생성자 추가 - DB접속이 필요할 때마다 동일한 코드를 JSP에서 반복해서 기술해야한다. 
<pre><code>
 public JDBConnect(String driver, String url, String id, String pwd) {
        try {
            // JDBC 드라이버 로드
            Class.forName(driver);  

            // DB에 연결
            con = DriverManager.getConnection(url, id, pwd);

            System.out.println("DB 연결 성공(인수 생성자 1)");
        }
        catch (Exception e) {            
            e.printStackTrace();
        }
    }
</code></pre>
- JDBConnect.java에 세 번째 생성자 추가 - 생성자는 매개변수로 application (JSP)내장 객체를 받는다.

<pre><code>
 // 세 번째 생성자
    public JDBConnect(ServletContext application) {
        try {
            // JDBC 드라이버 로드
            String driver = application.getInitParameter("OracleDriver"); 
            Class.forName(driver); 

            // DB에 연결
            String url = application.getInitParameter("OracleURL"); 
            String id = application.getInitParameter("OracleId");
            String pwd = application.getInitParameter("OraclePwd");
            con = DriverManager.getConnection(url, id, pwd);

            System.out.println("DB 연결 성공(인수 생성자 2)"); 
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    // 연결 해제(자원 반납)
    public void close() { 
        try {            
            if (rs != null) rs.close(); 
            if (stmt != null) stmt.close();
            if (psmt != null) psmt.close();
            if (con != null) con.close(); 

            System.out.println("JDBC 자원 해제");
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
</code></pre>

- 커넥션 풀 설정, 아래 코딩 추가
![image](https://user-images.githubusercontent.com/86938974/165971455-35236a87-1598-4ab9-a4be-bb9ba557b1ee.png)
<pre><code>
<Resource auth="Container" driverClassName="oracle.jdbc.OracleDriver" initialSize="0" maxIdle="20" maxTotal="20" maxWaitMillis="5000" minIdle="5" name="dbcp_myoracle" password="1234" type="javax.sql.DataSource" url="jdbc:oracle:thin:@localhost:1521:xe" username="musthave"/>
</code></pre>

-server.xml은 서버 전체와 관련한 설정, context.xml은 각각의 웹 애플리케이션마다 하나씩 주어지는 자원 설정, server.xml에 커넥션 풀을 전역 자원으로 선언하고, context.xml에서는 이를 참조하는 링크를 추가한다.

![image](https://user-images.githubusercontent.com/86938974/165971867-0529d9b4-845e-42f2-801b-8f12f1e932c4.png)
<pre><code>
<Context>
<ResourceLink global="dbcp_myoracle" name="dbcp_myoracle" type="javax.sql.DataSource"/>
</Context>
</code></pre>

- 커넥션 풀 동작 검증
![image](https://user-images.githubusercontent.com/86938974/165972173-40ccda28-d14b-4bbf-bb85-fc9087ee64ec.png)

<pre><code>
public class DBConnPool {
    public Connection con;
    public Statement stmt;
    public PreparedStatement psmt;
    public ResultSet rs;

    // 기본 생성자
    public DBConnPool() {
        try {
            // 커넥션 풀(DataSource) 얻기
            Context initCtx = new InitialContext();
            Context ctx = (Context)initCtx.lookup("java:comp/env");
            DataSource source = (DataSource)ctx.lookup("dbcp_myoracle");

            // 커넥션 풀을 통해 연결 얻기
            con = source.getConnection();

            System.out.println("DB 커넥션 풀 연결 성공");
        }
        catch (Exception e) {
            System.out.println("DB 커넥션 풀 연결 실패");
            e.printStackTrace();
        }
    }

    // 연결 해제(자원 반납)
    public void close() {
        try {            
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (psmt != null) psmt.close();
            if (con != null) con.close();  // 자동으로 커넥션 풀로 반납됨

            System.out.println("DB 커넥션 풀 자원 반납");
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
</code></pre>
*InitialContext : 자바의 네이밍 서비스에서 이름과 실제 객체를 연결해주는 개념, 네이밍 서비스를 이용하기 위한 시작점, 이 객체의 lookup 메서드에 이름을 건네 원하는 객체를 찾아온다.




