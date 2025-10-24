import math

theta = 2*math.pi/5
offset = math.pi/2
image_size = 20
radius = 30

def f(x):
    return round(radius*x+image_size*2,2)

for i in range(5):
    angle = theta*i - offset
    print(f'x="{f(math.cos(angle))}%" y="{f(-math.sin(angle))}%"')