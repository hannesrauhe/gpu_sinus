#include <iostream>
#include <vector>
#include <string>
#include <assert.h>

double time_in_seconds (void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec / 1000000.0;
}

template<class T>
bool compare_float(const T a,const T b) {
    const T eps = 0.000001;
    return fabs(b-a)<eps;
}

struct timestruct {
    timestruct() {}
    timestruct(const std::vector<float>& times, const std::vector<std::string>& names) : _times(times),_names(names),_runs(times.size(),-1) {}
    std::vector<float> _times;
    std::vector<std::string> _names;
    std::vector<int> _runs;

    static const float _tolerance = 50;

//    timestruct operator/(float div) {
//        std::vector<float> div_times;
//        for(std::vector<float>::iterator it = _times.begin();it!=_times.end();++it) {
//            div_times.push_back(*it/div);
//        }
//        return timestruct(div_times,_names);
//    }
//  timestruct operator+(const timestruct &t) {
//      return timestruct(partime+t.partime,transfer+t.transfer,seqtime+t.seqtime,overhead+t.overhead,kernel+t.kernel,run+1);
//  }

    void compare_approx(float a, float b, const char* time_p, int run) const {
        if(run && a!=0.0 && b>0.0) {
            float av = a/static_cast<float>(run);
            float a_begin = av - av*_tolerance/100;
            float a_end = av + av*_tolerance/100;
            if(b>a_end || b<a_begin) {
                std::cerr<<"High variance at run "<<run<<" of test "<< time_p <<", avg: "<<av<<", next value:"<<b<<" ("<< (b-av)/av*100.0 <<"%)"<<std::endl;
            }
        }
    }

    timestruct& add(float time, uint pos, const std::string& name) {
        if(pos>=_times.size()) {
            _times.resize(pos+1);
            _names.resize(pos+1);
            _runs.resize(pos+1);
        }
        assert(_runs[pos]>=0);
        _names[pos]=name;

        compare_approx(_times[pos], time, name.c_str(), _runs[pos]);
        _times[pos]+=time;
        _runs[pos]++;
        return *this;
    }

    timestruct& build_avg() {
        for(int i = 0; i<_times.size(); ++i) {
            _times[i]/=_runs[i];
            _runs[i]*=-1;
        }
        return *this;
    }

    void print(bool avg = true) {
        if(avg) {
            build_avg();
        }
//        for(int i = 0; i<_names.size(); ++i) {
//            printf("%s;",_names[i].c_str());
//        }
//        printf("\n");
        for(int i = 0; i<_times.size(); ++i) {
            printf("%.6f;",_times[i]);
        }
        printf("\n");
//        for(int i = 0; i<_runs.size(); ++i) {
//            printf("%d;",_runs[i]);
//        }
//        printf("\n");
    }
};
