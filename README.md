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


- 로그인 정보가 없을 때 로그인 페이지로 이동
![image](https://user-images.githubusercontent.com/86938974/166100949-dc4c951b-b607-46c4-bdda-794ef645fb93.png)

<pre><code>
<%@ page import="utils.JSFunction"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%
if (session.getAttribute("UserId") == null) {
    JSFunction.alertLocation("로그인 후 이용해주십시오.",
                             "LoginForm.jsp", out);
    return;
}
%>
</code></pre>
* 글쓰기 페이지 구현

![image](https://user-images.githubusercontent.com/86938974/166101648-1f166d01-3cf2-4643-a8ea-8d1ca109eb88.png)

    <%@ page language="java" contentType="text/html; charset=UTF-8"
        pageEncoding="UTF-8"%>
    <%@ include file="./IsLoggedIn.jsp"%> <!--로그인 확인-->
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <title>회원제 게시판</title>
    <script type="text/javascript">
    function validateForm(form) {  // 폼 내용 검증
        if (form.title.value == "") {
            alert("제목을 입력하세요.");
            form.title.focus();
            return false;
        }
        if (form.content.value == "") {
            alert("내용을 입력하세요.");
            form.content.focus();
            return false;
        }
    }
    </script>
    </head>
    <body>
    <jsp:include page="Link.jsp" />
    <h2>회원제 게시판 - 글쓰기(Write)</h2>
    <form name="writeFrm" method="post" action="WriteProcess.jsp"
          onsubmit="return validateForm(this);">
        <table border="1" width="90%">
            <tr>
                <td>제목</td>
                <td>
                    <input type="text" name="title" style="width: 90%;" />
                </td>
            </tr>
            <tr>
                <td>내용</td>
                <td>
                    <textarea name="content" style="width: 90%; height: 100px;"></textarea>
                </td>
            </tr>
            <tr>
                <td colspan="2" align="center">
                    <button type="submit">작성 완료</button>
                    <button type="reset">다시 입력</button>
                    <button type="button" onclick="location.href='List.jsp';">
                        목록 보기</button>
                </td>
            </tr>
        </table>
    </form>
    </body>
    </html>


- 글쓰기 페이지는 로그인해야 진입 가능하므로 IsLoggedIn.jsp 삽입
- 자바스크립트 함수를 통해 form의 필수 항목인 title과 content 확인, false를 return해주면 form의 action은 일어나지 않는다.

- DAO에 글쓰기 메서드 추가
<pre><code>
    // 게시글 데이터를 받아 DB에 추가합니다. 
    public int insertWrite(BoardDTO dto) {
        int result = 0;
        
        try {
            // INSERT 쿼리문 작성 
            String query = "INSERT INTO board ( "
                         + " num,title,content,id,visitcount) "
                         + " VALUES ( "
                         + " seq_board_num.NEXTVAL, ?, ?, ?, 0)";  

            psmt = con.prepareStatement(query);  // 동적 쿼리 
            psmt.setString(1, dto.getTitle());  
            psmt.setString(2, dto.getContent());
            psmt.setString(3, dto.getId());  
            
            result = psmt.executeUpdate(); 
        }
        catch (Exception e) {
            System.out.println("게시물 입력 중 예외 발생");
            e.printStackTrace();
        }
        
        return result;
    }
</code></pre>
- BoardDTO타입의 매개변수를 받은 후 데이터를 insert, insert에 성공한 행의 개수 정수로 반환

*글쓰기 처리 페이지 작성
![image](https://user-images.githubusercontent.com/86938974/166101788-1e8b3108-5c53-4f7c-bcca-4ef9959d2b81.png)
- 사용자가 글을 입력할 글쓰기 페이지와 글 내용을 데이터베이스에 저장해줄 DAO객체가 준비되었으니 이 둘을 연결해주면 됨

<pre><code>
<%@ page import="model1.board.BoardDAO"%>
<%@ page import="model1.board.BoardDTO"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ include file="./IsLoggedIn.jsp"%>
<%
// 폼값 받기
String title = request.getParameter("title");
String content = request.getParameter("content");

// 폼값을 DTO 객체에 저장
BoardDTO dto = new BoardDTO();
dto.setTitle(title);
dto.setContent(content);
dto.setId(session.getAttribute("UserId").toString());

// DAO 객체를 통해 DB에 DTO 저장
BoardDAO dao = new BoardDAO(application);

// 기존 코드
int iResult = dao.insertWrite(dto);

// 더미 데이터를 삽입하기 위한 코드
// int iResult = 0;
// for (int i = 1; i <= 100; i++) {
//     dto.setTitle(title + "-" + i); 
//     iResult = dao.insertWrite(dto);
// } 

dao.close();

// 성공 or 실패? 
if (iResult == 1) {
    response.sendRedirect("List.jsp");
} else {
    JSFunction.alertBack("글쓰기에 실패하였습니다.", out);
}
%>
</code></pre>
- 전송된 폼값을 DTO객체에 담아 앞에서 작성한 insertWrite()메소드를 호출해 DB에 저장한다. 
- session영역에 저장된 사용자 id를 DTO에 담은 이유는, board테이블의 id 컬럼은 member테이블의 id 컬럼과 외래키 설정되어 있으므로, id가 빈 값이면 INSERT시 참조 무결성 제약조건 위배가 되기 때문이다.
* 동작 확인
![image](https://user-images.githubusercontent.com/86938974/166101955-4051c82e-19ac-440d-b7f9-9a5e460ac5ff.png)
[확인] 버튼 누르면 로그인 페이지로 이동한다.
![image](https://user-images.githubusercontent.com/86938974/166101964-b58f4416-927a-435d-807b-5690a49ff1d8.png)
-로그인 성공 화면
![image](https://user-images.githubusercontent.com/86938974/166101978-9cee274b-992c-48a5-9638-716e3e246cb6.png)
- 글쓰기 화면
![image](https://user-images.githubusercontent.com/86938974/166102005-36c980e6-c964-404e-8227-8ac33a8f44ea.png)
- 새로 작성한 게시물 등록
![image](https://user-images.githubusercontent.com/86938974/166102023-d7bab266-ed44-4146-81e5-1c970d070fc0.png)
* 상세보기
- 사용자가 선택한 게시물 하나를 조회하여 보여주는 기능이므로 내용을 보려면 목록에서 원하는 게시물의 제목 클릭시, 게시물의 일련번호를 매개변수로 전달하고, 이를 이용해 데이터베이스에서 게시물 내용을 가져온다.
- DAO 준비
<pre><code>
 // 지정한 게시물을 찾아 내용을 반환합니다.
    public BoardDTO selectView(String num) { 
        BoardDTO dto = new BoardDTO();
        
        // 쿼리문 준비
        String query = "SELECT B.*, M.name " 
                     + " FROM member M INNER JOIN board B " 
                     + " ON M.id=B.id "
                     + " WHERE num=?";

        try {
            psmt = con.prepareStatement(query);
            psmt.setString(1, num);    // 인파라미터를 일련번호로 설정 
            rs = psmt.executeQuery();  // 쿼리 실행 

            // 결과 처리
            if (rs.next()) {
                dto.setNum(rs.getString(1)); 
                dto.setTitle(rs.getString(2));
                dto.setContent(rs.getString("content"));
                dto.setPostdate(rs.getDate("postdate"));
                dto.setId(rs.getString("id"));
                dto.setVisitcount(rs.getString(6));
                dto.setName(rs.getString("name")); 
            }
        } 
        catch (Exception e) {
            System.out.println("게시물 상세보기 중 예외 발생");
            e.printStackTrace();
        }
        
        return dto; 
    }
</code></pre>
- ResultSet 객체로 반환된 행을 next()메서드로 확인하고 DTO객체에 저장하여 반환해준다.

- 상세 보기 화면 작성
![image](https://user-images.githubusercontent.com/86938974/166102145-50ae3ea6-d030-4ef3-9306-98d73efa8a33.png)

<%@ page import="model1.board.BoardDAO"%>
<%@ page import="model1.board.BoardDTO"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
  pageEncoding="UTF-8"%>
<%
String num = request.getParameter("num");  // 일련번호 받기

BoardDAO dao = new BoardDAO(application);  // DAO 생성
dao.updateVisitCount(num);                 // 조회수 증가
BoardDTO dto = dao.selectView(num);        // 게시물 가져오기
dao.close();                               // DB 연결 해제
%>

<body>
<jsp:include page="Link.jsp" />  <!-- 공통 링크 -->

    <h2>회원제 게시판 - 내용 보기(View)</h2>
    <form name="writeFrm">
        <input type="hidden" name="num" value="<%= num %>" />
        <table border="1" width="90%">
            <tr>
                <td>번호</td>
                <td><%= dto.getNum() %></td>
                <td>작성자</td>
                <td><%= dto.getName() %></td>
            </tr>
            <tr>
                <td>작성일</td>
                <td><%= dto.getPostdate() %></td>
                <td>조회수</td>
                <td><%= dto.getVisitcount() %></td>
            </tr>
            <tr>
                <td>제목</td>
                <td colspan="3"><%= dto.getTitle() %></td>
            </tr>
            <tr>
                <td>내용</td>
                <td colspan="3" height="100">
                    <%= dto.getContent().replace("\r\n", "<br/>") %></td>
            </tr>
            <tr>
                <td colspan="4" align="center">
                    <%
                    if (session.getAttribute("UserId") != null
                        && session.getAttribute("UserId").toString().equals(dto.getId())) {
                    %>
                    <button type="button"
                            onclick="location.href='Edit.jsp?num=<%= dto.getNum() %>';">
                        수정하기</button>
                    <button type="button" onclick="deletePost();">삭제하기</button> 
                    <%
                    }
                    %>
                    <button type="button" onclick="location.href='List.jsp';">
                        목록 보기
                    </button>
                </td>
            </tr>
        </table>
    </form>
    </body>
    </html>

- List.jsp에서 넘겨받은 num 매개변수를 이용해 DAO객체를 생성한 후 조회수를 증가시키고 게시물 가져오기를 실행한다.

*수정하기
- 수정 폼 작성
![image](https://user-images.githubusercontent.com/86938974/166102347-c12cf867-819c-42c9-b84c-55b31f890095.png)

    <%@ page import="model1.board.BoardDAO"%>
    <%@ page import="model1.board.BoardDTO"%>
    <%@ page language="java" contentType="text/html; charset=UTF-8"
        pageEncoding="UTF-8"%>
    <%@ include file="./IsLoggedIn.jsp"%> 
    <%
    String num = request.getParameter("num");  // 일련번호 받기 
    BoardDAO dao = new BoardDAO(application);  // DAO 생성
    BoardDTO dto = dao.selectView(num);        // 게시물 가져오기 
    String sessionId = session.getAttribute("UserId").toString(); // 로그인 ID 얻기 
    if (!sessionId.equals(dto.getId())) {      // 본인인지 확인
        JSFunction.alertBack("작성자 본인만 수정할 수 있습니다.", out);
        return;
    }
    dao.close();  // DB 연결 해제
    %>
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <jsp:include page="Link.jsp" />
    <title>회원제 게시판</title>
    <script type="text/javascript">
    function validateForm(form) {  // 폼 내용 검증
        if (form.title.value == "") {
            alert("제목을 입력하세요.");
            form.title.focus();
            return false;
        }
        if (form.content.value == "") {
            alert("내용을 입력하세요.");
            form.content.focus();
            return false;
        }
    }
    </script>
    </head>
    <body>
    <jsp:include page="Link.jsp" />
    <h2>회원제 게시판 - 수정하기(Edit)</h2>
    <form name="writeFrm" method="post" action="EditProcess.jsp"
          onsubmit="return validateForm(this);">
        <input type="hidden" name="num" value="<%= dto.getNum() %>" /> 
        <table border="1" width="90%">
            <tr>
                <td>제목</td>
                <td>
                    <input type="text" name="title" style="width: 90%;" 
                           value="<%= dto.getTitle() %>"/> 
                </td>
            </tr>
            <tr>
                <td>내용</td>
                <td>
                    <textarea name="content" style="width: 90%; height: 100px;"><%= dto.getContent() %></textarea>
                </td>
            </tr>
            <tr>
                <td colspan="2" align="center">
                    <button type="submit">작성 완료</button>
                    <button type="reset">다시 입력</button>
                    <button type="button" onclick="location.href='List.jsp';">
                        목록 보기</button>
                </td>
            </tr>
        </table>
    </form>
    </body>
    </html>

- 수정하기 페이지에서도 로그인한 상태인지 확인하기 위해 IsLoggedIn.jsp 인크루드한다.
- hidden 속성의 input 태그를 사용하여 선택된 게시물의 일련번호를 EditProcess.jsp에 그대로 전달하는 역할을 수행

- 게시물 수정 DAO 준비
<pre><code>
 // 지정한 게시물을 수정합니다.
    public int updateEdit(BoardDTO dto) { 
        int result = 0;
        
        try {
            // 쿼리문 템플릿 
            String query = "UPDATE board SET "
                         + " title=?, content=? "
                         + " WHERE num=?";
            
            // 쿼리문 완성
            psmt = con.prepareStatement(query);
            psmt.setString(1, dto.getTitle());
            psmt.setString(2, dto.getContent());
            psmt.setString(3, dto.getNum());
            
            // 쿼리문 실행 
            result = psmt.executeUpdate();
        } 
        catch (Exception e) {
            System.out.println("게시물 수정 중 예외 발생");
            e.printStackTrace();
        }
        
        return result; // 결과 반환 
    }
</code></pre>
- 반환하는 값은 업데이트된 행의 개수이다.

- 수정 처리 페이지 작성
![image](https://user-images.githubusercontent.com/86938974/166104795-8296fd67-71fe-4a36-bcaf-c19c7df66b5e.png)

    <%@ page import="model1.board.BoardDAO"%>
    <%@ page import="model1.board.BoardDTO"%>
    <%@ page language="java" contentType="text/html; charset=UTF-8"
        pageEncoding="UTF-8"%>
    <%@ include file="./IsLoggedIn.jsp"%>
    <%
    // 수정 내용 얻기
    String num = request.getParameter("num");
    String title = request.getParameter("title");
    String content = request.getParameter("content");

    // DTO에 저장
    BoardDTO dto = new BoardDTO();
    dto.setNum(num);
    dto.setTitle(title);
    dto.setContent(content);

    // DB에 반영
    BoardDAO dao = new BoardDAO(application);
    int affected = dao.updateEdit(dto);
    dao.close();

    // 성공/실패 처리
    if (affected == 1) {
        // 성공 시 상세 보기 페이지로 이동
        response.sendRedirect("View.jsp?num=" + dto.getNum());
    }
    else {
        // 실패 시 이전 페이지로 이동
        JSFunction.alertBack("수정하기에 실패하였습니다.", out);
    }
    %>


- 폼값 받은 후 DTO 객체에 저장, DAO객체를 생성해 updateEdit()메서드 호출, 문제없이 수정했다면 1이 반환되어 수정에 성공하면 상세 페이지로, 실패하면 이전 페이지로 이동한다.

* 삭제하기
- 삭제하기 버튼에 삭제 요청 로직 달기
- View.jsp에 내용을 추가한다.

    function deletePost() {
        var confirmed = confirm("정말로 삭제하겠습니까?");
        if (confirmed) {
            var form = document.writeFrm;       // 이름(name)이 "writeFrm"인 폼 선택
            form.method = "post";               // 전송 방식
            form.action = "DeleteProcess.jsp";  // 전송 경로
            form.submit();                      // 폼값 전송
        }
    }

    <button type="button" onclick="deletePost();">삭제하기</button> 

-삭제하기 버튼을 클릭하면 onclick="deletPost();"코드에 의해 설정된 전송 방식과 전송 경로로 데이터가 전송된다. 이 때 hidden 타입으로 정의한 일련번호도 전송된다.

- 삭제처리를 위한 메서드 DAO클래스에 추가
<pre><code>
// 지정한 게시물을 삭제합니다.
    public int deletePost(BoardDTO dto) { 
        int result = 0;

        try {
            // 쿼리문 템플릿
            String query = "DELETE FROM board WHERE num=?"; 

            // 쿼리문 완성
            psmt = con.prepareStatement(query); 
            psmt.setString(1, dto.getNum()); 

            // 쿼리문 실행
            result = psmt.executeUpdate(); 
        } 
        catch (Exception e) {
            System.out.println("게시물 삭제 중 예외 발생");
            e.printStackTrace();
        }
        
        return result; // 결과 반환
    }
</code></pre>

- 삭제 처리 페이지 작성
![image](https://user-images.githubusercontent.com/86938974/166104778-8b002e07-f444-45e8-adff-5ba46b589d99.png)

    <%@ page import="model1.board.BoardDAO"%>
    <%@ page import="model1.board.BoardDTO"%>
    <%@ page language="java" contentType="text/html; charset=UTF-8"
        pageEncoding="UTF-8"%>
    <%@ include file="./IsLoggedIn.jsp"%>
    <%
    String num = request.getParameter("num");  // 일련번호 얻기 

    BoardDTO dto = new BoardDTO();             // DTO 객체 생성
    BoardDAO dao = new BoardDAO(application);  // DAO 객체 생성
    dto = dao.selectView(num);  // 주어진 일련번호에 해당하는 기존 게시물 얻기

    // 로그인된 사용자 ID 얻기
    String sessionId = session.getAttribute("UserId").toString(); 

    int delResult = 0;

    if (sessionId.equals(dto.getId())) {  // 작성자가 본인인지 확인 
        // 작성자가 본인이면...
        dto.setNum(num);
        delResult = dao.deletePost(dto);  // 삭제!!! 
        dao.close();

        // 성공/실패 처리
        if (delResult == 1) { 
            // 성공 시 목록 페이지로 이동
            JSFunction.alertLocation("삭제되었습니다.", "List.jsp", out); 
        } else {
            // 실패 시 이전 페이지로 이동
            JSFunction.alertBack("삭제에 실패하였습니다.", out);
        } 
    } 
    else { 
        // 작성자 본인이 아니라면 이전 페이지로 이동
        JSFunction.alertBack("본인만 삭제할 수 있습니다.", out);

        return;
    }
    %>

- 로그인 아이디와 게시물 작성자가 같은지 확인 후 deletePost()메서드를 호출하여 게시물을 삭제한다.
- 삭제에 성공하면 목록 페이지로, 실패하면 뒤로 이동한다.

![image](https://user-images.githubusercontent.com/86938974/166104774-c73baf16-4b6d-429a-813c-25b85ac59d54.png)

* 페이징 기능 넣기
- 페이징을 위한 설정
- 두 가지 기본 설정 값
1. 한 페이지에 출력할 게시물의 개수 (POSTS_PER_PAGE = 10)
2. 한 화면(블록)에 출력할 페이지의 개수 (PAGES_PER_BLOCK = 5)

*페이징 구현 절차
- 1단계 : board 테이블에 저장된 전체 레코드 수 카운트 -> 전체 게시물이 105개라 가정
- 2단계 : 각 페이지에서 출력할 게시물의 범위 계산
    - 계산식
        - 범위의 시작 값 : (현재 페이지 -1) * POSTS_PER_PAGE+1
        - 범위의 종료 값 : (현재 페이지*POSTS_PER_PAGE)
- 3단계 : 전체 페이지 수 계산
    이때 계산된 결과는 무조건 올림 처리 -> 마지막 페이지의 게시물 5개도 조회해야 한다.
    - 계산식
        - Math.ceil(전체 게시물 수/POSTS_PER_PAGE)
- 4단계 : '이전 페이지 블록 바로가기' 출력
    계산식 : ((현재 페이지-1) / PAGES_PER_BLOCK)*PAGES_PER_BLOCK + 1
- 5단계 : 각 페이지 번호 출력
    - 단계 4에서 계산한 pageTemp를 BLOCK_PAGE만큼 반복하면서 +1 연산 후 출력
- 6단계 : '다음 페이지 블록 바로가기' 출력
    - 각 페이지 번호를 출력한 후 pageTemp +1 하여 다음 페이지 블록 바로가기를 설정

* 더미 데이터 입력 (WriteProcess.jsp)

<pre><code>
int iResult = 0;
for (int i = 1; i <= 100; i++) {
     dto.setTitle(title + "-" + i); 
     iResult = dao.insertWrite(dto);
 } 
</code></pre>

* 페이징용 쿼리문 작성
- 첫 번째 페이지에 출력할 게시물을 가져오기 위해 rownum은 1~10까지로 지정
<pre><code>
select * from(
    select Tb.*, rownum rNum From(
        select*from board order by num desc
    ) tb
)
where rNum Between 1 and 10;
</code></pre>

-DAO 수정
<pre><code>
 // 검색 조건에 맞는 게시물 목록을 반환합니다(페이징 기능 지원).
    public List<BoardDTO> selectListPage(Map<String, Object> map) {
        List<BoardDTO> bbs = new Vector<BoardDTO>();  // 결과(게시물 목록)를 담을 변수
        
        // 쿼리문 템플릿  
        String query = " SELECT * FROM ( "
                     + "    SELECT Tb.*, ROWNUM rNum FROM ( "
                     + "        SELECT * FROM board ";

        // 검색 조건 추가 
        if (map.get("searchWord") != null) {
            query += " WHERE " + map.get("searchField")
                   + " LIKE '%" + map.get("searchWord") + "%' ";
        }
        
        query += "      ORDER BY num DESC "
               + "     ) Tb "
               + " ) "
               + " WHERE rNum BETWEEN ? AND ?"; 

        try {
            // 쿼리문 완성 
            psmt = con.prepareStatement(query);
            psmt.setString(1, map.get("start").toString());
            psmt.setString(2, map.get("end").toString());
            
            // 쿼리문 실행 
            rs = psmt.executeQuery();
            
            while (rs.next()) {
                // 한 행(게시물 하나)의 데이터를 DTO에 저장
                BoardDTO dto = new BoardDTO();
                dto.setNum(rs.getString("num"));
                dto.setTitle(rs.getString("title"));
                dto.setContent(rs.getString("content"));
                dto.setPostdate(rs.getDate("postdate"));
                dto.setId(rs.getString("id"));
                dto.setVisitcount(rs.getString("visitcount"));

                // 반환할 결과 목록에 게시물 추가
                bbs.add(dto);
            }
        } 
        catch (Exception e) {
            System.out.println("게시물 조회 중 예외 발생");
            e.printStackTrace();
        }
        
        // 목록 반환
        return bbs;
    }
</code></pre>
- 앞에서 사용한 rownum을 이용한 쿼리문 작성한다. 

* List.jsp 수정
- DAO가 준비되었으니 List.jsp에서도 코드를 추가한다.
- 그에 앞서 페이징 관련 설정값을 web.xml에 정의하도록한다.

<pre><code>
    <context-param>
        <param-name>POSTS_PER_PAGE</param-name>
        <param-value>10</param-value>
      </context-param>
      <context-param>
        <param-name>PAGES_PER_BLOCK</param-name>
        <param-value>5</param-value>
      </context-param>
</code></pre>

-List.jsp에 코드 추가
<pre><code>
/*** 페이지 처리 start ***/
// 전체 페이지 수 계산
int pageSize = Integer.parseInt(application.getInitParameter("POSTS_PER_PAGE"));
int blockPage = Integer.parseInt(application.getInitParameter("PAGES_PER_BLOCK"));
int totalPage = (int)Math.ceil((double)totalCount / pageSize); // 전체 페이지 수

// 현재 페이지 확인
int pageNum = 1;  // 기본값
String pageTemp = request.getParameter("pageNum");
if (pageTemp != null && !pageTemp.equals(""))
    pageNum = Integer.parseInt(pageTemp); // 요청받은 페이지로 수정

// 목록에 출력할 게시물 범위 계산
int start = (pageNum - 1) * pageSize + 1;  // 첫 게시물 번호
int end = pageNum * pageSize; // 마지막 게시물 번호
param.put("start", start);
param.put("end", end);
/*** 페이지 처리 end ***/
List<BoardDTO> boardLists = dao.selectListPage(param);  // 게시물 목록 받기
dao.close();  // DB 연결 닫기
</code></pre>

* 바로가기 HTML 코드 생성
- 목록에 출력할 게시물을 가져왔으니, 화면에 출력하도록 한다.
- utils/BoardPage.java생성
![image](https://user-images.githubusercontent.com/86938974/166104760-b65bb718-1d5a-424a-ad95-9e56964269db.png)
<pre><code>
package utils;

public class BoardPage {
    public static String pagingStr(int totalCount, int pageSize, int blockPage,
            int pageNum, String reqUrl) {
        String pagingStr = "";

        // 단계 3 : 전체 페이지 수 계산
        int totalPages = (int) (Math.ceil(((double) totalCount / pageSize)));

        // 단계 4 : '이전 페이지 블록 바로가기' 출력
        int pageTemp = (((pageNum - 1) / blockPage) * blockPage) + 1;
        if (pageTemp != 1) {
            pagingStr += "<a href='" + reqUrl + "?pageNum=1'>[첫 페이지]</a>";
            pagingStr += "&nbsp;";
            pagingStr += "<a href='" + reqUrl + "?pageNum=" + (pageTemp - 1)
                         + "'>[이전 블록]</a>";
        }

        // 단계 5 : 각 페이지 번호 출력
        int blockCount = 1;
        while (blockCount <= blockPage && pageTemp <= totalPages) {
            if (pageTemp == pageNum) {
                // 현재 페이지는 링크를 걸지 않음
                pagingStr += "&nbsp;" + pageTemp + "&nbsp;";
            } else {
                pagingStr += "&nbsp;<a href='" + reqUrl + "?pageNum=" + pageTemp
                             + "'>" + pageTemp + "</a>&nbsp;";
            }
            pageTemp++;
            blockCount++;
        }

        // 단계 6 : '다음 페이지 블록 바로가기' 출력
        if (pageTemp <= totalPages) {
            pagingStr += "<a href='" + reqUrl + "?pageNum=" + pageTemp
                         + "'>[다음 블록]</a>";
            pagingStr += "&nbsp;";
            pagingStr += "<a href='" + reqUrl + "?pageNum=" + totalPages
                         + "'>[마지막 페이지]</a>";
        }

        return pagingStr;
    }
}
</code></pre>

*화면 출력
- List.jsp에 추가
<pre><code>
<%@ page import="utils.BoardPage"%>

<h2>목록 보기(List) - 현재 페이지 : <%= pageNum %> (전체 : <%= totalPage %>)</h2>

// 게시물이 있을 때
    int virtualNum = 0;  // 화면상에서의 게시물 번호
    int countNum = 0;
    for (BoardDTO dto : boardLists)
    {
        // virtualNumber = totalCount--;  // 전체 게시물 수에서 시작해 1씩 감소
        virtualNum = totalCount - (((pageNum - 1) * pageSize) + countNum++);
%>

<tr align="center">
            <!--페이징 처리-->
            <td>
                <%= BoardPage.pagingStr(totalCount, pageSize,
                       blockPage, pageNum, request.getRequestURI()) %>  
            </td>
            <!--글쓰기 버튼-->
</code></pre>

![image](https://user-images.githubusercontent.com/86938974/166104742-01f360d1-3c6b-48fa-b471-c6be2f89aeb9.png)
- 다음블록 링크 누른 후
![image](https://user-images.githubusercontent.com/86938974/166104737-e89665ee-db53-4431-90dc-1ce439af78e1.png)

