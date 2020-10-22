import { Howl } from "howler";

export class HowlWrapper {
    constructor() {
        this._playing = false;
        this._src = null;
        this._duration = 0;
        this._rate = 1;
        this._volume = 1;
        this._muted = false;
        this._title = "None Playing";
        this._thumb = "https://via.placeholder.com/150?text=BroJogan";
        this._howl = null;
    }

    loadNew(src, title, progress, thumb, 
        onload = ()=>{}, 
        onplay = ()=>{},
        onpause = ()=>{},
        onstop = ()=>{},
        onseek = ()=>{}
    ) {
        this._playing = false;
        this._title = title;
        this._thumb = thumb;
        this._howl = new Howl({
            src: [src],
            autoplay: true,
            volume: this._volume,
            mute: this._muted,
            rate: this._rate,
            html5: true,
            preload: 'metadata',
            onload: () => {
                alert("audio loaded");
                this._duration = this._howl.duration();
                onload();
            },
            onplay: id => {
                alert("audio playing");
                this._playing = true;
                this._howl.seek(progress);
                onplay();
            },
            onpause: id => {
                this._playing = false;
                alert("sending progress " + this._howl.seek() + " to backend because it was paused");
                onpause();
            },
            onstop: id => {
                this._playing = false;
                alert("sending progress " + this._howl.seek() + " to backend because it was stopped");
                onstop();
            },
            onseek: id => {
                // todo: send progress to backend
                alert("sending progress " + this._howl.seek() + " to backend because it was seeked");
                onseek();
            }
        });
    }

    play() {
        if (this._howl) {
            this._howl.play();
        }
    }

    pause() {
       if (this._howl) {
            this._howl.pause();
        }
    }

    set mute(_mute) {
        if (!_mute instanceof Boolean) {
            throw "mute must be Noolean";
        }
        this._muted = _mute;
        if (this._howl) {
            this._howl.mute(this._muted);
        }
    }

    get mute() {
        return this._muted;
    }

    set volume(_volume) {
        if (!_volume instanceof Number) {
            throw "volume must be Number";
        }
        if (_volume < 0 || _volume > 1) {
            throw "volume must be between 0 and 1 inclusive";
        }
        this._volume = _volume;
        if (this._howl) {
            this._howl.volume(this._volume);
        }
    }

    get volume() {
        return this._volume;
    }

    /**
     * @param {number} _rate
     */
    set rate(_rate) {
        if (!_rate instanceof Number) {
            throw "rate must be Number";
        }
        if (_rate < 0.5 || _rate > 4) {
            throw "rate must be between 0.5 and 4.0 inclusive";
        }
        this._rate = _rate;
        if (this._howl) {
            this._howl.rate(this._rate);
        }
    }

    get rate() {
        return this._rate;
    }
}

export const currentlyPlaying = HowlWrapper();