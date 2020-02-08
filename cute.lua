-- cute: coroutine cutscene lib

cute={
    -- visibility for draw state
    -- 0=hidden,1=fully visible
    vis=0,
    -- current frame
    frame={},
    -- max text width
    width=25,
    rows=2,
    -- autoplay interval delay
    autoplay_interval=60
}

-- draw/update the bound
-- coroutine, if there is one.
function cute:draw()
    if self.co then
        if costatus(self.co)=="dead" then
            -- unset if a cutscene
            -- is not being played,
            -- allowing games to
            -- test if a cutscene
            -- is currently active
            self.co=nil
        else
            coresume(self.co)
            cute:draw_frame()
        end
    end
end

-- slide in.
function cute:slide_in(⧗)
    ⧗=⧗ or 30
    for t=1,⧗ do
        cute.vis=ease_outquint(t,0,1,⧗)
        yield()
    end
end

-- slide out.
function cute:slide_out(⧗)
    ⧗=⧗ or 30
    for t=1,⧗ do
        cute.vis=ease_inquint(t,1,-1,⧗)
        yield()
    end
end

-- wraps a cutscene routine
-- in a function that will
-- provide
-- enter/leave transitions
function cute:cinematic(label)
    local enter=cocreate(cute.slide_in)
    local leave=cocreate(cute.slide_out)
    local func=cocreate(label)

    -- calling once draws the first
    -- cutscene frame before doing anim
    coresume(func)

    local list={
        enter,
        func,
        leave
    }

    for co in all(list) do
        repeat
            yield(coresume(co))
        until costatus(co)=="dead"
    end
end

function slice(arr,start,fin)
 local out={}
 for i=start,fin do
    add(out,arr[i])
 end
 return out
end

-- cute dialogue
function cute:d(a,m,auto)
    -- todo: resolve actor
    -- could be string, object..

    if type(a)=="string" then
        a={name=a,color=7}
    end

    local frame={
        a=a,
        ⬇️=false,
        ⧗=0
    }

    local row=1
    local lines=split(m,self.width)
    local progress=0
    local autoplay_timeout=self.autoplay_interval

    -- workaround for bug where a single line of
    -- text is skipped, fix this...
    if (#lines==1) add(lines,"")

    -- typewriter speed
    local speed=0.4

    repeat
        local text=join(slice(lines,row,row+self.rows-1),"\n")

        frame.⬇️=row+self.rows-1<#lines
        frame.⧗+=1
        frame.m=sub(text,0,progress)
        self.frame=frame
        yield()

        if auto then
            autoplay_timeout-=1

            if autoplay_timeout==0 then
                if progress>=#text then
                    row+=1
                    progress=#lines[row]
                end

                autoplay_timeout=self.autoplay_interval
            end
        elseif btnp(❎) then
            if progress>=#text then
                row+=1
                progress=0
                for i=row,row+self.rows-2 do
                 if (lines[i]) progress+=#lines[i]
                end
                printh("???")
            else
                progress=#text
            end
        end

        if progress<#text then
            local mult=1

            if btn(❎) then
                mult=2
            end

            progress+=speed*mult
        end
    until row>#lines-1

    printh("dialogue event completed: "..m)
end

function cute:play(func)
    cute.co=cocreate(func)
end

-- ease functions from easing.lua
-- quintic ease out
function ease_outquint(t,b,c,d)
    t/=d
    t-=1
    return c*(t*t*t*t*t+1)+b
end

-- quintic ease in/out
function ease_inquint(t,b,c,d)
    t/=d/2
    if (t<1) return c/2*t*t*t*t*t+b
    t-=2
    return c/2*(t*t*t*t*t+2)+b
end

-- join an array of strings per the delimiter
function join(strings,delimiter)
				local ret=""

				for l in all(strings) do
	 	 	 	 if ret=="" then
	  	  	  	  ret=l
	 	 	 	 else
 	  	  	  	 ret=ret..delimiter..l
	 	 	 	 end
				end

    return ret
end

-- split a string into an array
-- of lines based on position
-- of spacing characters
-- todo: transform
-- into cursor-oriented
-- coroutine for memory
-- efficiency?
function split(str,w)
    local out,from,len={},1,#str

    repeat
        local to=min(from+w,len)

        if to<len then
            -- look ahead to width and
            -- backtrack until we
            -- see a space
            for c=min(to,len),from,-1 do
                if sub(str,c,c)==" " then
                    to=c
                    break
                end
            end
        end

        add(out,sub(
            str,
            from,
            to
        ))

        from=to+1
    until to>=len

    return out
end