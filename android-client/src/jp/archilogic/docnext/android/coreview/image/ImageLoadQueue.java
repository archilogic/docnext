package jp.archilogic.docnext.android.coreview.image;

import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.SortedMap;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

import com.google.common.collect.Iterators;
import com.google.common.collect.Maps;

/**
 * Only implements methods using by ThreadPoolExecutor
 */
public class ImageLoadQueue implements BlockingQueue< Runnable > {
    // <Level, Map<Page, ... > >
    private final SortedMap< Integer , SortedMap< Integer , Queue< LoadBitmapTask > > > _queue =
            Maps.newTreeMap();
    private final ReentrantLock _lock = new ReentrantLock( true );
    private final Condition _notEmpty = _lock.newCondition();

    private int _page;

    @Override
    public boolean add( final Runnable e ) {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public boolean addAll( final Collection< ? extends Runnable > c ) {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public void clear() {
        _queue.clear();
    }

    @Override
    public boolean contains( final Object object ) {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public boolean containsAll( final Collection< ? > c ) {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public int drainTo( final Collection< ? super Runnable > c ) {
        if ( c == null ) {
            throw new NullPointerException();
        }

        if ( c == this ) {
            throw new IllegalArgumentException();
        }

        final ReentrantLock lock = _lock;
        lock.lock();

        try {
            int n = 0;

            for ( final Entry< Integer , SortedMap< Integer , Queue< LoadBitmapTask > > > map : _queue
                    .entrySet() ) {
                for ( final Entry< Integer , Queue< LoadBitmapTask > > entry : map.getValue()
                        .entrySet() ) {
                    final Queue< LoadBitmapTask > queue = entry.getValue();

                    c.addAll( queue );
                    n += queue.size();
                }
            }

            _queue.clear();

            return n;
        } finally {
            lock.unlock();
        }
    }

    @Override
    public int drainTo( final Collection< ? super Runnable > c , final int maxElements ) {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public LoadBitmapTask element() {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public boolean isEmpty() {
        return size() == 0;
    }

    @Override
    public Iterator< Runnable > iterator() {
        return Iterators.forArray( ( Runnable[] ) toArray() );
    }

    @Override
    public boolean offer( final Runnable e ) {
        final ReentrantLock lock = _lock;
        lock.lock();

        try {
            if ( e instanceof LoadBitmapTask ) {
                final LoadBitmapTask task = ( LoadBitmapTask ) e;

                SortedMap< Integer , Queue< LoadBitmapTask > > levelMap = _queue.get( task.level );

                if ( levelMap == null ) {
                    _queue.put( task.level ,
                            levelMap = Maps.< Integer , Queue< LoadBitmapTask >> newTreeMap() );
                }

                Queue< LoadBitmapTask > pageQueue = levelMap.get( task.page );

                if ( pageQueue == null ) {
                    levelMap.put( task.page , pageQueue = new LinkedList< LoadBitmapTask >() );
                }

                final boolean ok = pageQueue.offer( task );
                assert ok;

                _notEmpty.signal();

                return true;
            } else {
                throw new RuntimeException();
            }
        } finally {
            lock.unlock();
        }
    }

    @Override
    public boolean offer( final Runnable e , final long timeout , final TimeUnit unit )
            throws InterruptedException {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public LoadBitmapTask peek() {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public LoadBitmapTask poll() {
        final ReentrantLock lock = _lock;
        lock.lock();

        try {
            return pollHelper();
        } finally {
            lock.unlock();
        }
    }

    @Override
    public LoadBitmapTask poll( final long timeout , final TimeUnit unit )
            throws InterruptedException {
        long nanos = unit.toNanos( timeout );

        final ReentrantLock lock = _lock;
        lock.lockInterruptibly();

        try {
            for ( ; ; ) {
                final LoadBitmapTask x = pollHelper();

                if ( x != null ) {
                    return x;
                }

                if ( nanos <= 0 ) {
                    return null;
                }

                try {
                    nanos = _notEmpty.awaitNanos( nanos );
                } catch ( final InterruptedException ie ) {
                    _notEmpty.signal(); // propagate to non-interrupted thread
                    throw ie;
                }
            }
        } finally {
            lock.unlock();
        }
    }

    private LoadBitmapTask pollHelper() {
        if ( _queue.isEmpty() ) {
            return null;
        }
        final int level = _queue.firstKey();
        final SortedMap< Integer , Queue< LoadBitmapTask > > levelMap = _queue.get( level );

        for ( int delta = 0 ; ; delta++ ) {
            if ( _page + delta > levelMap.lastKey() && _page - delta < levelMap.firstKey() ) {
                throw new RuntimeException( "page: " + _page + ", firstKey: " + levelMap.firstKey()
                        + ", lastKey: " + levelMap.lastKey() );
            }

            for ( final int sign : new int[] { 1 , -1 } ) {
                if ( delta == 0 && sign == -1 ) {
                    continue;
                }

                final Queue< LoadBitmapTask > pageQueue = levelMap.get( _page + delta * sign );

                if ( pageQueue != null ) {
                    final LoadBitmapTask ret = pageQueue.poll();

                    if ( pageQueue.isEmpty() ) {
                        levelMap.remove( _page + delta * sign );

                        if ( levelMap.isEmpty() ) {
                            _queue.remove( level );
                        }
                    }

                    return ret;
                }
            }
        }
    }

    @Override
    public void put( final Runnable e ) throws InterruptedException {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public int remainingCapacity() {
        return Integer.MAX_VALUE;
    }

    @Override
    public LoadBitmapTask remove() {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public boolean remove( final Object object ) {
        final ReentrantLock lock = _lock;
        lock.lock();

        try {
            boolean ret = false;

            if ( object instanceof LoadBitmapTask ) {
                final LoadBitmapTask task = ( LoadBitmapTask ) object;

                final Map< Integer , Queue< LoadBitmapTask >> levelMap = _queue.get( task.level );
                final Queue< LoadBitmapTask > pageQueue = levelMap.get( task.page );

                ret = pageQueue.remove( task );

                if ( pageQueue.isEmpty() ) {
                    levelMap.remove( task.page );

                    if ( levelMap.isEmpty() ) {
                        _queue.remove( task.level );
                    }
                }
            }

            return ret;
        } finally {
            lock.unlock();
        }
    }

    @Override
    public boolean removeAll( final Collection< ? > c ) {
        throw new RuntimeException( "Not Implemented" );
    }

    @Override
    public boolean retainAll( final Collection< ? > c ) {
        throw new RuntimeException( "Not Implemented" );
    }

    public void setPage( final int page ) {
        final ReentrantLock lock = _lock;
        lock.lock();

        try {
            _page = page;
        } finally {
            lock.unlock();
        }
    }

    @Override
    public int size() {
        final ReentrantLock lock = _lock;
        lock.lock();

        try {
            int n = 0;

            for ( final Entry< Integer , SortedMap< Integer , Queue< LoadBitmapTask >> > levelMap : _queue
                    .entrySet() ) {
                for ( final Entry< Integer , Queue< LoadBitmapTask > > pageQueue : levelMap
                        .getValue().entrySet() ) {
                    n += pageQueue.getValue().size();
                }
            }

            return n;
        } finally {
            lock.unlock();
        }
    }

    @Override
    public LoadBitmapTask take() throws InterruptedException {
        final ReentrantLock lock = _lock;
        lock.lockInterruptibly();

        try {
            try {
                while ( size() == 0 ) {
                    _notEmpty.await();
                }
            } catch ( final InterruptedException ie ) {
                _notEmpty.signal(); // propagate to non-interrupted thread
                throw ie;
            }

            final LoadBitmapTask x = pollHelper();
            assert x != null;

            return x;
        } finally {
            lock.unlock();
        }
    }

    @Override
    public Object[] toArray() {
        final ReentrantLock lock = _lock;
        lock.lock();

        try {
            final Object[] ret = new Object[ size() ];

            int n = 0;
            for ( final Entry< Integer , SortedMap< Integer , Queue< LoadBitmapTask >> > levelMap : _queue
                    .entrySet() ) {
                for ( final Entry< Integer , Queue< LoadBitmapTask > > pageQueue : levelMap
                        .getValue().entrySet() ) {
                    for ( final LoadBitmapTask task : pageQueue.getValue() ) {
                        ret[ n++ ] = task;
                    }
                }
            }

            return ret;
        } finally {
            lock.unlock();
        }
    }

    @Override
    public < T > T[] toArray( T[] array ) {
        throw new RuntimeException( "Not Implemented" );
    }
}
