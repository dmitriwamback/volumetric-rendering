//
//  core.h
//  volumetric_rendering
//
//  Created by Dmitri Wamback on 2025-06-10.
//

#include <GL/glew.h>
#include <glfw3.h>

GLFWwindow* window;

void initialize() {
    
    glfwInit();
    
#if defined(__APPLE__)
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    
    window = glfwCreateWindow(1200, 800, "Volumetric Rendering", nullptr, nullptr);
    glfwMakeContextCurrent(window);
    
    glewExperimental = GL_TRUE;
    glewInit();
    glEnable(GL_DEPTH_TEST);
    
    while (!glfwWindowShouldClose(window)) {
        
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glClearColor(0.3, 0.3, 0.3, 0.0);
        
        glfwPollEvents();
        glfwSwapBuffers(window);
    }
}
