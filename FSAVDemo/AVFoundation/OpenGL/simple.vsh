// Vertex Shader
attribute vec4 v_position;
attribute vec4 v_color;

varying mediump vec4 f_color;

void main(void) {
    f_color = v_color; // 通过 attribute 通道获取颜色信息，后续传给片元着色器
    gl_Position = v_position; // 通过 attribute 通道获取顶点信息
}
