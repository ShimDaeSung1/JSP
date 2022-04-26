<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%
String popupMode="on"; //팝업창을 출력여부를 결정하는 Flag.

Cookie[] cookies=request.getCookies();
if(cookies!=null){
	for(Cookie c : cookies){
		String cookieName=c.getName();
		String cookieValue=c.getValue();
		if(cookieName.equals("PopupClose")){ // PopupClose쿠키이면
			popupMode=cookieValue;// popupMode변경
		}
	}
}
%>    
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>팝업</title>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<script>
	$(function(){
		//닫기버튼을 누르면 Ajax요청
		$("#closeBtn").click(function(){
			//팝업창을 안보이게
			$("#popup").hide();
			//체크박스의 값 구하기
			var chkVal=$("#inactiveToday:checked").val();			
			console.log(chkVal);
			//chVal가 1이 아니면 서버에 요청 안함
			if(chkVal!=1){
				return;
			}
			
			$.ajax({
				url:'PopupCookie2.jsp',//서버주소
				type:'get',//전송방식
				data: {inactiveToday : chkVal}, //서버쪽으로 전달하는 데이터
				dataType: "text", // 서버에서 보내주는 데이터의 형식
				success: function(resData){
						console.log(resData);
						$("#status").text(resData);
					}				
			});
			
		});
	});
</script>
<style>
	#popup{
		position:absolute; top:100px; left:100px; color:yellow;
		width:300px; height:100px; background:gray;
	}
	#popup>div{
		position:relative; top:0px;  color:black;
		border:1px solid gray; padding: 10px;background:#ffffff;
	}
</style>
</head>
<body>
	<h2>팝업 메인 페이지</h2>
	현재 팝업창은 <span id="status"><%=popupMode%></span> 상태입니다.<br>
<%
	//out.print("현재 팝업창은 " + popupMode +" 상태입니다.<br>");
%>
<pre>
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
	컨텐츠입니다.
</pre>
<% //popupMode가 on이면 팝업창 출력, off이면 출력하지 않음
	if (popupMode.equals("on")){
%>		
		<div id="popup">
			<h2 align="center">공지사항 팝업입니다.</h2>
			<div align="right">
				<form name="popFrm">
					<input type="checkbox" id="inactiveToday" value="1"> 하루동안 열지않음
					<input type="button" value="닫기" id="closeBtn">					
				</form>
			</div>
		</div>
<% } %>		
		
		

</body>
</html>