// ─── Attachment union ─────────────────────────────────────────────────────────

export interface CompanionIntroAttachment {
  type: 'companion_intro'
  name: string
  species: string
}

export interface FileAttachment {
  type: 'file'
  name: string
  content: string
  mimeType?: string
}

export interface ImageAttachment {
  type: 'image'
  name: string
  url: string
}

export type Attachment =
  | CompanionIntroAttachment
  | FileAttachment
  | ImageAttachment
