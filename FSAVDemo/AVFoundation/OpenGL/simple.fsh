// Fragment Shader
varying mediump vec4 f_color;

void main(void) {
    gl_FragColor = f_color; // 从顶点着色器转传过来的 f_color。
}
