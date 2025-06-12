//
//  deferred_renderer.h
//  volumetric_rendering
//
//  Created by Dmitri Wamback on 2025-06-10.
//

#ifndef deferred_renderer_h
#define deferred_renderer_h

class DeferredRenderer {
public:
    uint32_t position, distanceToCamera, normal, albedo;
    
    static DeferredRenderer Create();
    void Update();
    void Bind();
    void Unbind();
    
private:
    uint32_t framebufferObject, renderbufferObject;
    void AssignParameters();
};

DeferredRenderer DeferredRenderer::Create() {
    
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    
    DeferredRenderer renderer = DeferredRenderer();

    glGenFramebuffers(1, &renderer.framebufferObject);
    glBindFramebuffer(GL_FRAMEBUFFER, renderer.framebufferObject);
    
    glGenRenderbuffers(1, &renderer.renderbufferObject);
    
    glGenTextures(1, &renderer.position);
    glBindTexture(GL_TEXTURE_2D, renderer.position);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGB, GL_FLOAT, 0);
    renderer.AssignParameters();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderer.position, 0);
    
    glGenTextures(1, &renderer.distanceToCamera);
    glBindTexture(GL_TEXTURE_2D, renderer.distanceToCamera);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R16F, width, height, 0, GL_RED, GL_FLOAT, 0);
    renderer.AssignParameters();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + 1, GL_TEXTURE_2D, renderer.distanceToCamera, 0);
    
    glGenTextures(1, &renderer.normal);
    glBindTexture(GL_TEXTURE_2D, renderer.normal);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGB, GL_FLOAT, 0);
    renderer.AssignParameters();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + 2, GL_TEXTURE_2D, renderer.normal, 0);
    
    glGenTextures(1, &renderer.albedo);
    glBindTexture(GL_TEXTURE_2D, renderer.albedo);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    renderer.AssignParameters();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + 3, GL_TEXTURE_2D, renderer.albedo, 0);
    
    uint32_t attachments[4] = {
        GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT3
    };
    
    glDrawBuffers(4, attachments);
    
    glBindRenderbuffer(GL_RENDERBUFFER, renderer.renderbufferObject);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, renderer.renderbufferObject);
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return renderer;
}

void DeferredRenderer::Update() {
    
    glBindFramebuffer(GL_FRAMEBUFFER, framebufferObject);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbufferObject);
    
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    
    glBindTexture(GL_TEXTURE_2D, position);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_FLOAT, 0);
    
    glBindTexture(GL_TEXTURE_2D, distanceToCamera);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_FLOAT, 0);
    
    glBindTexture(GL_TEXTURE_2D, normal);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_FLOAT, 0);
    
    glBindTexture(GL_TEXTURE_2D, albedo);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
    
}

void DeferredRenderer::Bind() {
    Update();
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebufferObject);
}

void DeferredRenderer::Unbind() {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void DeferredRenderer::AssignParameters() {
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

#endif /* deferred_renderer_h */
