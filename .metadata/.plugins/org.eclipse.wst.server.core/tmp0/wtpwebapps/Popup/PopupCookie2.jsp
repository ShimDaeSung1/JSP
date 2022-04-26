<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%
//클라이언트가 보내온 inactiveToday수집
String chkVal=request.getParameter("inactiveToday");

//inactiveToday의 값이 1이면 쿠키를 생성. 24시간유지
if(chkVal!=null && chkVal.equals("1")){
	Cookie cookie=new Cookie("PopupClose","off");//쿠키생성
	cookie.setMaxAge(60*60*24);//24시간보관
	response.addCookie(cookie);
	//클라이언트로 메시지 전송(출력)
	out.println("off");// Text형식		
}
%>