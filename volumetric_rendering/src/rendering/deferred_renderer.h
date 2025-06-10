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
    void InitializeTexture(uint32_t textureId, uint32_t colorAttachmentOffset, int width, int height);
};

DeferredRenderer DeferredRenderer::Create() {
    
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    
    DeferredRenderer renderer = DeferredRenderer();

    glGenFramebuffers(1, &renderer.framebufferObject);
    glBindFramebuffer(GL_FRAMEBUFFER, renderer.framebufferObject);
    
    glGenRenderbuffers(1, &renderer.renderbufferObject);
    
    glGenTextures(1, &renderer.position);
    renderer.InitializeTexture(renderer.position, 0, width, height);
    
    glGenTextures(1, &renderer.distanceToCamera);
    renderer.InitializeTexture(renderer.distanceToCamera, 1, width, height);
    
    glGenTextures(1, &renderer.normal);
    renderer.InitializeTexture(renderer.normal, 2, width, height);
    
    glGenTextures(1, &renderer.albedo);
    renderer.InitializeTexture(renderer.albedo, 3, width, height);
    
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
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glBindTexture(GL_TEXTURE_2D, distanceToCamera);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glBindTexture(GL_TEXTURE_2D, normal);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glBindTexture(GL_TEXTURE_2D, albedo);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
    
}

void DeferredRenderer::Bind() {
    Update();
    glBindFramebuffer(GL_FRAMEBUFFER, framebufferObject);
}

void DeferredRenderer::Unbind() {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void DeferredRenderer::InitializeTexture(uint32_t textureId, uint32_t colorAttachmentOffset, int width, int height) {
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + colorAttachmentOffset, GL_TEXTURE_2D, textureId, 0);
}

#endif /* deferred_renderer_h */
