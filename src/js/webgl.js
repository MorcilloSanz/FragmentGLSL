let running = true;

function initWebGL() {
        
    const canvas = document.getElementById('webgl-canvas');
    const gl = canvas.getContext('webgl');

    if (!gl) {
        console.error('Unable to initialize WebGL. Your browser may not support it.');
        return;
    }

    // Shaders
    const vertexShaderCode = `
    attribute vec2 a_position;
    void main() {
        gl_Position = vec4(a_position, 0.0, 1.0);
    }
    `;

    let fragmentShaderCode = editor.getValue();

    // Compile shaders
    const vertexShader = compileShader(gl, vertexShaderCode, gl.VERTEX_SHADER);
    let fragmentShader = compileShader(gl, fragmentShaderCode, gl.FRAGMENT_SHADER);

    // Create shader program
    const program = createProgram(gl, vertexShader, fragmentShader);
    const positionAttributeLocation = gl.getAttribLocation(program, 'a_position');

    // Quad vertices
    const positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    const positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

    // Attributes
    gl.useProgram(program);
    gl.enableVertexAttribArray(positionAttributeLocation);
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.vertexAttribPointer(positionAttributeLocation, 2, gl.FLOAT, false, 0, 0);

    let startTime = Date.now();

    // Render scene
    render();

    function compileProgram(code) {

        const newFragmentShader = compileShader(gl, code, gl.FRAGMENT_SHADER);
        gl.detachShader(program, fragmentShader);
        gl.deleteShader(fragmentShader);

        return newFragmentShader;
    }

    function render() {

        if(running) {
            
            let compiled = false;
            let newFragmentShader = null;

            fragmentShaderCode = editor.getValue();

            let errorOutput = document.getElementById('error-output');

            try {
                newFragmentShader = compileProgram(fragmentShaderCode);
                compiled = true;
            }
            catch(error) {
                errorOutput.innerHTML = error;
                errorOutput.style.backgroundColor = "#ff334e";
            }
            
            if(compiled && newFragmentShader != null) {

                fragmentShader = newFragmentShader;
                gl.attachShader(program, fragmentShader);
                gl.linkProgram(program);

                if (!gl.getProgramParameter(program, gl.LINK_STATUS) && program != null) {
                    console.error('Program linking failed:', gl.getProgramInfoLog(program));
                    return;
                }

                gl.useProgram(program);

                // Uniforms
                const uTime = Date.now() - startTime;
                uniformFloat(gl, "u_time", uTime, program);

                uniformVec2(gl, "u_resolution", 400, 400, program);

                // Draw call
                gl.clearColor(0.0, 0.0, 0.0, 1.0);
                gl.clear(gl.COLOR_BUFFER_BIT);
                gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

                // Clear error
                errorOutput.innerHTML = "<p style='padding: 10px'><strong>Compiled</strong> successfully</p>";
                errorOutput.style.backgroundColor = "green";
            }
        }

        // Request next frame (rendering loop)
        requestAnimationFrame(render);
    }
}

function compileShader(gl, source, type) {

    const shader = gl.createShader(type);

    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        let error = gl.getShaderInfoLog(shader);
        gl.deleteShader(shader);
        throw("<p style='padding: 10px'><strong>Compilation failed: </strong>" + error + "</p>");
    }

    return shader;
}

function createProgram(gl, vertexShader, fragmentShader) {

    const program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        let error = gl.getProgramInfoLog(program);
        gl.deleteProgram(program);
        throw("<p style='padding: 10px'><strong>Linking failed: </strong>" + error + "</p>");
    }

    return program;
}

function uniformFloat(gl, name, value, program) {
    let location = gl.getUniformLocation(program, name);
    gl.uniform1f(location, value);
}

function uniformVec2(gl, name, a, b, program) {
    let location = gl.getUniformLocation(program, name);
    gl.uniform2f(location, a, b);
}