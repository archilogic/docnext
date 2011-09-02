package jp.archilogic.docnext.converter;

public interface IEntityToDtoConverter< E , D > {
    D toDto( E entity );
}
