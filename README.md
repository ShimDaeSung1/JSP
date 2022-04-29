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

![image](https://user-images.githubusercontent.com/86938974/165973731-f04bb5e1-8408-4435-8d7c-8f2c4d99357f.png)

-server.xml은 서버 전체와 관련한 설정, context.xml은 각각의 웹 애플리케이션마다 하나씩 주어지는 자원 설정, server.xml에 커넥션 풀을 전역 자원으로 선언하고, context.xml에서는 이를 참조하는 링크를 추가한다.

![image](https://user-images.githubusercontent.com/86938974/165971867-0529d9b4-845e-42f2-801b-8f12f1e932c4.png)
![image](https://user-images.githubusercontent.com/86938974/165973763-292c5728-de23-43b9-be11-83fc121527ef.png)

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

* 로직
- 로그인 상태 : 글쓰기, 수정하기, 삭제하기
- 글쓰기 후 : 목록 이동
- 수정 후 : 상세 보기 이동
- 삭제 후 : 목록 이동
- 페이징 처리
* 활용 기술
- 지시어
- 스크립트 요소(스크립틀릿, 표현식)
- 내장 객체(request, response, out, session, application)
- JDBC(DAO/DTO)
- 자바스크립트

*모델 1 방식
- 클라이언트의 요청을 받아 JSP(뷰와 컨트롤러)와 자바빈즈(모델) 그리고 DB가 서로 데이터를 주고받아 응답해주는 구조이다.
* 구현 순서
- DB생성
- DTO생성(Model 값 저장)
- DAO생성(CRUD담당)
- view생성(jsp) 
============

*DTO와 DAO준비
![image](https://user-images.githubusercontent.com/86938974/165974919-2c4b43a5-851d-4012-ae74-d2782bdf5e4b.png)

<pre><code>
public class BoardDTO {
    // 멤버 변수 선언
    private String num;
    private String title;
    private String content;
    private String id;
    private java.sql.Date postdate;
    private String visitcount;
    private String name;
</code></pre>
- 멤버 변수 선언 후 [Source] -> [Generate Getters and Setters...]메뉴를 통해 게터와 세터를 자동으로 생성해준다.

<pre><code>
 // 검색 조건에 맞는 게시물의 개수를 반환합니다.
    public int selectCount(Map<String, Object> map) {
        int totalCount = 0; // 결과(게시물 수)를 담을 변수

        // 게시물 수를 얻어오는 쿼리문 작성
        String query = "SELECT COUNT(*) FROM board";
        if (map.get("searchWord") != null) {
            query += " WHERE " + map.get("searchField") + " "
                   + " LIKE '%" + map.get("searchWord") + "%'";
        }

        try {
            stmt = con.createStatement();   // 쿼리문 생성
            rs = stmt.executeQuery(query);  // 쿼리 실행
            rs.next();  // 커서를 첫 번째 행으로 이동
            totalCount = rs.getInt(1);  // 첫 번째 칼럼 값을 가져옴
        }
        catch (Exception e) {
            System.out.println("게시물 수를 구하는 중 예외 발생");
            e.printStackTrace();
        }

        return totalCount; 
    }
</code></pre>

-다음은 게시물을 가져오는 메서드
<pre><code>
// 검색 조건에 맞는 게시물 목록을 반환합니다.
    public List<BoardDTO> selectList(Map<String, Object> map) { 
        List<BoardDTO> bbs = new Vector<BoardDTO>();  // 결과(게시물 목록)를 담을 변수

        String query = "SELECT * FROM board "; 
        if (map.get("searchWord") != null) {
            query += " WHERE " + map.get("searchField") + " "
                   + " LIKE '%" + map.get("searchWord") + "%' ";
        }
        query += " ORDER BY num DESC "; 

        try {
            stmt = con.createStatement();   // 쿼리문 생성
            rs = stmt.executeQuery(query);  // 쿼리 실행

            while (rs.next()) {  // 결과를 순화하며...
                // 한 행(게시물 하나)의 내용을 DTO에 저장
                BoardDTO dto = new BoardDTO(); 

                dto.setNum(rs.getString("num"));          // 일련번호
                dto.setTitle(rs.getString("title"));      // 제목
                dto.setContent(rs.getString("content"));  // 내용
                dto.setPostdate(rs.getDate("postdate"));  // 작성일
                dto.setId(rs.getString("id"));            // 작성자 아이디
                dto.setVisitcount(rs.getString("visitcount"));  // 조회수

                bbs.add(dto);  // 결과 목록에 저장
            }
        } 
        catch (Exception e) {
            System.out.println("게시물 조회 중 예외 발생");
            e.printStackTrace();
        }

        return bbs;
    }
</code></pre>
- rs.next()로 ResultSet에 저장된 행을 하나씩 불러와 하나의 행의 내용을 DTO객체에 저장 후 List컬렉션에 담아 bbs에 저장하여 JSP로 반환해준다.

*게시물 목록 출력하기
![image](https://user-images.githubusercontent.com/86938974/165976716-f9d78b72-ee48-4015-90a6-07d94c4aaa6c.png)
<pre><code>
<%
// DAO를 생성해 DB에 연결
BoardDAO dao = new BoardDAO(application);

// 사용자가 입력한 검색 조건을 Map에 저장
Map<String, Object> param = new HashMap<String, Object>(); 
String searchField = request.getParameter("searchField");
String searchWord = request.getParameter("searchWord");
if (searchWord != null) {
    param.put("searchField", searchField);
    param.put("searchWord", searchWord);
}

int totalCount = dao.selectCount(param);  // 게시물 수 확인
List<BoardDTO> boardLists = dao.selectList(param);  // 게시물 목록 받기
dao.close();  // DB 연결 닫기
%>
</code></pre>

*JSP코드
<pre><code>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>회원제 게시판</title>
</head>
<body>
    <jsp:include page="Link.jsp" />  <!-- 공통 링크 -->

    <h2>목록 보기(List)</h2>
    <!-- 검색폼 --> 
    <form method="get">  
    <table border="1" width="90%">
    <tr>
        <td align="center">
            <select name="searchField"> 
                <option value="title">제목</option> 
                <option value="content">내용</option>
            </select>
            <input type="text" name="searchWord" />
            <input type="submit" value="검색하기" />
        </td>
    </tr>   
    </table>
    </form>
    <!-- 게시물 목록 테이블(표) --> 
    <table border="1" width="90%">
        <!-- 각 칼럼의 이름 --> 
        <tr>
            <th width="10%">번호</th>
            <th width="50%">제목</th>
            <th width="15%">작성자</th>
            <th width="10%">조회수</th>
            <th width="15%">작성일</th>
        </tr>
        <!-- 목록의 내용 --> 
<%
if (boardLists.isEmpty()) {
    // 게시물이 하나도 없을 때 
%>
        <tr>
            <td colspan="5" align="center">
                등록된 게시물이 없습니다^^*
            </td>
        </tr>
<%
}
else {
    // 게시물이 있을 때 
    int virtualNum = 0;  // 화면상에서의 게시물 번호
    for (BoardDTO dto : boardLists)
    {
        virtualNum = totalCount--;  // 전체 게시물 수에서 시작해 1씩 감소
%>
        <tr align="center">
            <td><%= virtualNum %></td>  <!--게시물 번호-->
            <td align="left">  <!--제목(+ 하이퍼링크)-->
                <a href="View.jsp?num=<%= dto.getNum() %>"><%= dto.getTitle() %></a> 
            </td>
            <td align="center"><%= dto.getId() %></td>          <!--작성자 아이디-->
            <td align="center"><%= dto.getVisitcount() %></td>  <!--조회수-->
            <td align="center"><%= dto.getPostdate() %></td>    <!--작성일-->
        </tr>
<%
    }
}
%>
    </table>
    <!--목록 하단의 [글쓰기] 버튼-->
    <table border="1" width="90%">
        <tr align="right">
            <td><button type="button" onclick="location.href='Write.jsp';">글쓰기
                </button></td>
        </tr>
    </table>
</body>
</html>
</code></pre>








