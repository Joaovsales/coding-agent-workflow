# Technology Stack: PDF Idea Generator v2

This document outlines the core technologies and frameworks utilized in the PDF Idea Generator v2 project, based on the analysis of its codebase and configuration.

## 1. Backend

*   **Language & Framework:** Python (FastAPI) - For building high-performance, asynchronous APIs.
*   **Database:** Supabase (PostgreSQL with `pgvector` extension) - Provides robust relational data storage and vector embedding capabilities for semantic search.
*   **Caching & Task Queue:** Redis, ARQ - Redis is used for caching and as a broker for ARQ, an asynchronous task queue for background processing (e.g., PDF processing pipeline).
*   **AI/ML Integration:** OpenAI API - Utilized for generating text embeddings (e.g., `text-embedding-3-small`) and for content generation (e.g., `GPT-4o-mini`).
*   **Cloud Storage:** AWS S3 - For efficient and scalable storage of PDF files.

## 2. Frontend

*   **Library & Build Tool:** React, Vite - React for building dynamic user interfaces, and Vite for a fast development server and optimized builds.
*   **UI Components & Styling:** Radix UI, TailwindCSS - Radix UI provides unstyled, accessible component primitives, while TailwindCSS offers a utility-first CSS framework for rapid styling.

## 3. Infrastructure & Development Tools

*   **Containerization:** Docker - For containerizing the application services, ensuring consistent development and deployment environments.
*   **Testing Frameworks:**
    *   **Backend:** Pytest - A mature and flexible testing framework for Python applications.
    *   **Frontend:** Vitest - A fast unit test framework powered by Vite, compatible with modern web projects.
