#ifndef SIMPLEX_DOWNHILL_H
#define SIMPLEX_DOWNHILL_H

template <typename T>
struct ParamPoint
{
    typedef float *cost_function(T* params, int params_length);
    int length;
    T* params;
    float value;    
};



template <typename T>
void addValue(float value, int pos, T* p, ParamPoint<T>* points)
{
    points[pos].value = value;
    for (int i=0;i<points[pos].length;++i) {
        points[pos][i] = p[i];
    }
    int j=pos;
    while (j>0 && points.value[j]<points.value[j-1]) {
        swap(points[j],points[j-1]);
        --j;
    }
    
}

template <typename T>
float optimizeSimplexDownhill(ParamPoint<T>* points, int points_length, ParamPoint<T>::cost_function func)
{
    const int MAX_ITERATIONS = 10;
    int n = points_length - 1;
    
    assert(n>0);
    assert(points[0].length==n);
    
    T* p_o = new T[n];
    T* p_r = new T[n];
    T* p_e = new T[n];
    
    
    int iterations = 0;
    
    for (int i=0;i<n+1;++i) {
        float val = func(points[i].params);
        addValue(val,i, points[i].params, points);
    }



    while (true) {
    
        if (iterations++ > MAX_ITERATIONS) break;
    
//      debug logger.info(sprint("Current params: {}",params));
//      debug logger.info(sprint("Current costs: {}",vals));
        memset(p_o,0,n*sizeof(T));
        for (int j=0;j<n;++j) {
            for (int i=0;i<n;++i) {
                p_o[i] += points[j].params[i];
            }
        }
        for (int i=0;i<n;++i) {
            p_o[i] /= n;
        }
        
        bool converged = true;
        for (int i=0;i<n;++i) {
            if (p_o[i] != points[n].params[i]) {
                converged = false;
            }
        }
        if (converged) break;
        
        for (int i=0;i<n;++i) {
            p_r[i] = 2*p_o[i]-points[n].params[i];
        }
        float val_r = func(p_r,n);

//      debug logger.info(sprint("Computing p_r={} from p_o={} and params[n]={}... val_r={}",p_r,p_o,params[n],val_r));
        
        if (val_r>points[0].value && val_r<points[n-1].value) {
//          debug logger.info("Reflection");
            addValue(val_r,n,p_r, points);
            continue;
        }
        if (val_r<=points[0].value) {
            for (int i=0;i<n;++i) {
                p_e[i] = 2*p_r[i]-p_o[i];
            }
            float val_e = func(p_e,n);
            
            if (val_e<val_r) {
//              debug logger.info(sprint("Reflection and expansion, val_e={}",val_e));
                addValue(val_e,n,p_e,points);
            }
            else {
//              debug logger.info("Reflection without expansion");
                addValue(val_r,n,p_r,points);
            }
            continue;
        }
        if (vals[n-1]<val_r && val_r<vals[n]) {
            for (int i=0;i<n;++i) {
                p_e[i] = (3*p_o[i]-params[n][i])/2;
            }
            float val_e = func(p_e,n);
            
            if (val_e<val_r) {
//              debug logger.info(sprint("Reflexion and contraction, val_c={}",val_e));
                addValue(val_e,n,p_e,points);
            }
            else {
//              debug logger.info("Reflexion without contraction");
                addValue(val_r,n,p_r,points);
            }
            continue;
        }
        if (val_r>=vals[n]) {
            for (int i=0;i<n;++i) {
                p_e[i] = (p_o[i]+params[n][i])/2;
            }
            float val_e = func(p_e,n);
            
            if (val_e<vals[n]) {
//              debug logger.info(sprint("Just contraction, new val[n]={}",val_e));
                addValue(val_e,n,p_e,points);
                continue;
            }
        }
        {
//          debug logger.info(sprint("Full contraction: {}",params));
            for (int j=1;j<=n;++j) {
                for (int i=0;i<n;++i) {
                    params[j][i] = (params[j][i]+params[0][i])/2;
                }
                float val = func(params[j],n);
                addValue(val,j,params[j],points);
            }
        }
    }
    
    
    float bestVal = vals[0];
    
    delete p_r;
    delete p_o;
    delete p_e;
    
    return bestVal;
}

#endif //SIMPLEX_DOWNHILL_H