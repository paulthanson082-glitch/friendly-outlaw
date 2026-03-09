import { Router, Request, Response } from 'express';
import { templateService } from '../services/templateService.js';
import { authMiddleware } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

/**
 * GET /api/templates
 * Get all templates (default + user-created)
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { category } = req.query;

    const templates = templateService.getTemplates(userId);

    // Filter by category if provided
    const filtered = category
      ? templates.filter((t) => t.category === category)
      : templates;

    res.json(filtered);
  })
);

/**
 * GET /api/templates/:id
 * Get a specific template
 */
router.get(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;

    const template = templateService.getTemplate(id);
    if (!template) {
      throw new NotFoundError('Template');
    }

    res.json(template);
  })
);

/**
 * POST /api/templates
 * Create a custom template
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { name, category, content, placeholders, description } = req.body;

    if (!name || !category || !content) {
      throw new ValidationError('name, category, and content are required');
    }

    const template = templateService.createTemplate(
      userId,
      name,
      category,
      content,
      placeholders || [],
      description || ''
    );

    res.status(201).json(template);
  })
);

/**
 * POST /api/templates/:id/fill
 * Fill template with values and return filled content
 */
router.post(
  '/:id/fill',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const { values } = req.body;

    if (!values || typeof values !== 'object') {
      throw new ValidationError('values object is required');
    }

    try {
      const filled = templateService.fillTemplate(id, values);
      res.json({ content: filled });
    } catch (error) {
      throw new NotFoundError('Template');
    }
  })
);

/**
 * POST /api/templates/:id/create-doc
 * Create a new document from template with filled values
 */
router.post(
  '/:id/create-doc',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const { title, values } = req.body;

    if (!title) {
      throw new ValidationError('title is required');
    }

    const template = templateService.getTemplate(id);
    if (!template) {
      throw new NotFoundError('Template');
    }

    const filledContent = templateService.fillTemplate(id, values || {});

    // Use documentService to create document
    const { documentService } = await import('../services/documentService.js');
    const doc = documentService.createDocument(userId, title, filledContent, template.category, id);

    res.status(201).json(doc);
  })
);

export default router;
