<%@page import="java.sql.PreparedStatement"%>
<%@page import="common.JDBConnect"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
	<h2>회원 입력 테스트</h2>
<%
JDBConnect jdbc=new JDBConnect();
String id="test2";
String pass="2222";
String name="테스트2회원";

String sql="insert into member values(?,?,?,sysdate)";
PreparedStatement psmt=jdbc.con.prepareStatement(sql);
psmt.setString(1,id);
psmt.setString(2,pass);
psmt.setString(3,name);
//영향을 받은 행의 수(1)이 리턴됨. insert문이 실행되면 1행이 추가되므로 영향받은 행의 수는 1
int inResult=psmt.executeUpdate();
out.println(inResult+"행이 입력되었습니다.");
jdbc.close();
%>	
</body>
</html>