courses = ['History', 'Math', 'Physics', 'CompSci']
student = {'name': 'John', 'age': '25'}

if student.get('courses') == None:
    student['courses'] = courses
    
print(student)

if student.get('phone') == None:
    student['phone'] = '555-5555'

print(student) 