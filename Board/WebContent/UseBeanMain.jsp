<%@page import="common.Person"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>액션 태그 - UseBean</title>
</head>
<body>
	<h2>useBean 액션 태그</h2>
	<h3>자바빈즈 생성하기</h3>
	<jsp:useBean id = "person" class ="common.Person" scope= "request"></jsp:useBean>
	
	<h3>setProperty 액션 태그로 자바빈즈 속성 지정하기</h3>
	<jsp:setProperty name = "person" property="name" value="임꺽정"></jsp:setProperty>
	<jsp:setProperty name = "person" property="age" value="41"></jsp:setProperty>
	
	<h3>getProperty 액션 태그로 자바빈즈 속성 읽기</h3>
	<ul>
		<li>이름 : <jsp:getProperty name="person" property="name"></jsp:getProperty></li>
		<li>나이 : <jsp:getProperty name="person" property="age"></jsp:getProperty></li>
	</ul>
	
	<%
	//위와 아래는 같음
	Person person1 = new Person();
	person1.setName("이순신");
	person1.setAge(41);
	%>
	<%= person1.getName() %>
	<%= person1.getAge() %>
</body>
</html>