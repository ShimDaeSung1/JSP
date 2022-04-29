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
	<c:forEach begin="1" end="100" var="j">
		<c:if test="${j mod 2 ne 0}">
			<c:set var = "sum" value="${sum+j}"/>
		</c:if>
	</c:forEach>
	1~100사이 홀수의 합은? ${sum}
</body>
</html>