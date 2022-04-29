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
	<c:set var="iTag">
		i태그는 <i>기울임</i>을 표현합니다.
	</c:set>
	<h3>${iTag}</h3>
	<h3><c:out value="${iTag}"></c:out></h3>
	<h3><c:out value="${iTag}" escapeXml="false"></c:out></h3>
</body>
</html>