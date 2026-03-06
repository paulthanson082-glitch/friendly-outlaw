import { Router, Request, Response } from 'express';
import { documentService } from '../services/documentService.js';
import { authMiddleware } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

const router = Router();

// Require authentication for all document routes
router.use(authMiddleware);

/**
 * POST /api/documents
 * Create a new document
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { title, content, category, templateId } = req.body;

    if (!title) {
      throw new ValidationError('title is required');
    }

    const doc = documentService.createDocument(userId, title, content || '', category, templateId);
    res.status(201).json(doc);
  })
);

/**
 * GET /api/documents
 * Get all documents for the current user
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { limit = '50', offset = '0' } = req.query;

    const docs = documentService.getUserDocuments(userId, parseInt(limit as string), parseInt(offset as string));
    const stats = documentService.getStatistics(userId);

    res.json({ documents: docs, ...stats });
  })
);

/**
 * GET /api/documents/search
 * Search documents
 */
router.get(
  '/search',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { q } = req.query;

    if (!q) {
      throw new ValidationError('q (query) parameter is required');
    }

    const results = documentService.searchDocuments(userId, q as string);
    res.json(results);
  })
);

/**
 * GET /api/documents/:id
 * Get a specific document
 */
router.get(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const doc = documentService.getDocument(id);
    if (!doc || doc.userId !== userId) {
      throw new NotFoundError('Document');
    }

    res.json(doc);
  })
);

/**
 * PUT /api/documents/:id
 * Update a document
 */
router.put(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const { title, content, category, metadata } = req.body;

    const doc = documentService.getDocument(id);
    if (!doc || doc.userId !== userId) {
      throw new NotFoundError('Document');
    }

    const updated = documentService.updateDocument(id, {
      title,
      content,
      category,
      metadata,
    } as any);

    res.json(updated);
  })
);

/**
 * DELETE /api/documents/:id
 * Delete a document (soft delete)
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const doc = documentService.getDocument(id);
    if (!doc || doc.userId !== userId) {
      throw new NotFoundError('Document');
    }

    documentService.deleteDocument(id);
    res.status(204).send();
  })
);

/**
 * GET /api/documents/:id/export
 * Export document in different formats
 */
router.get(
  '/:id/export',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const { format = 'markdown' } = req.query;

    const doc = documentService.getDocument(id);
    if (!doc || doc.userId !== userId) {
      throw new NotFoundError('Document');
    }

    const exported = documentService.exportDocument(id, format as any);
    if (!exported) {
      throw new ValidationError('Invalid export format. Use: markdown, plaintext, or html');
    }

    const mimeTypes: Record<string, string> = {
      markdown: 'text/markdown',
      plaintext: 'text/plain',
      html: 'text/html',
    };

    res.setHeader('Content-Type', mimeTypes[format as string] || 'text/plain');
    res.setHeader('Content-Disposition', `attachment; filename="${doc.title}.${format}"`);
    res.send(exported);
  })
);

/**
 * POST /api/documents/:id/duplicate
 * Duplicate a document
 */
router.post(
  '/:id/duplicate',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const doc = documentService.getDocument(id);
    if (!doc || doc.userId !== userId) {
      throw new NotFoundError('Document');
    }

    const duplicated = documentService.createDocument(
      userId,
      `${doc.title} (Copy)`,
      doc.content,
      doc.category,
      doc.templateId
    );

    res.status(201).json(duplicated);
  })
);

export default router;
