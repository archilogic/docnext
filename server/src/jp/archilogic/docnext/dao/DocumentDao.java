package jp.archilogic.docnext.dao;

import java.util.List;

import jp.archilogic.docnext.entity.Document;

import org.hibernate.criterion.DetachedCriteria;
import org.hibernate.criterion.Restrictions;
import org.springframework.stereotype.Component;

@Component
public class DocumentDao extends GenericDao< Document , Long > {
    @SuppressWarnings( "unchecked" )
    public List< Document > findAlmostAll() {
        return getHibernateTemplate().findByCriteria( DetachedCriteria.forClass( Document.class ).add( Restrictions.eq( "processing" , false ) ) );
    }
}
