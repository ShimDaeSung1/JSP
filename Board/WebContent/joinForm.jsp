<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>회원가입</title>
    <script>
    function check(){
    	if(document.frm.id.value==""){
    		alert("id를 입력하세요!");
    		document.frm.id.focus();
    		return false;
    	}
    }
    function check2(){
    	if(document.frm.id.value==""){
    		alert("id를 입력하세요!");
    		document.frm.id.focus();  
    		return;
    	}
    	document.frm.submit();//form전송
    }
    </script>
</head>
<body>
    <h1>회원가입</h1>
    <form name="frm" action="join.jsp" method="post" onsubmit="return check();">
        id <input type="text" name="id"><br>
        pw <input type="password" name="password"><br>
        name <input type="text" name="name"><br>
        email <input type="email" name="name"><br>
        tel <input type="text" name="tel"><br>
        성별 <input type="radio" name="gender" value="m">남자
            <input type="radio" name="gender" value="f">여자<br>
        취미 <input type="checkbox" name="hobby1" value="독서">독서
             <input type="checkbox" name="hobby2" value="운동">운동
             <input type="checkbox" name="hobby3" value="등산">등산<br>
        직업 <select name="job">
            <option value="학생">학생</option>
            <option value="직장인">직장인</option>
            <option value="공무원">공무원</option>
        </select><br>
        자기소개 <br>
        <textarea name="introduce" cols="50" rows="10"></textarea><br> 
        <input type="submit" value="가입">
        <input type="button" value="가입" onclick="check2()">
            

    </form>
</body>
</html>