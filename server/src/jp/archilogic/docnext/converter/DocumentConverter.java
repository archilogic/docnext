package jp.archilogic.docnext.converter;

import jp.archilogic.docnext.dto.DocumentResDto;
import jp.archilogic.docnext.entity.Document;

import org.springframework.stereotype.Component;

@Component
public class DocumentConverter implements IEntityToDtoConverter< Document , DocumentResDto > {
    @Override
    public DocumentResDto toDto( final Document entity ) {
        final DocumentResDto dto = new DocumentResDto();

        dto.id = entity.id;
        dto.name = entity.getName();

        return dto;
    }
}
