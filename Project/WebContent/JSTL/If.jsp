<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
	<c:set var="number" value = "100"/>
	<c:set var="string" value = "JSP"/>
	<c:if test="${number mod 2 eq 0}" var = "result">
		${number}는 짝수입니다.<br>
	</c:if>
	result : ${result}<br>
	<c:if test= "${string eq 'JSP'}">
		문자열은 JSP입니다.
	</c:if>
</body>
</html>